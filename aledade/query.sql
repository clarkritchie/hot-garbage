DROP FUNCTION fetch_and_process_transactions;
-- CREATE OR REPLACE FUNCTION fetch_and_process_transactions(OUT month VARCHAR, OUT balance INTEGER, OUT cc_transactions INTEGER) RETURNS SETOF RECORD AS $$
CREATE OR REPLACE FUNCTION fetch_and_process_transactions() RETURNS INTEGER AS $$
DECLARE
    -- Declare a variable to store the aggregated value
    total_balance INTEGER := 0;

    -- Declare variables to store fetched values
    month_value VARCHAR;
    balance_value INTEGER;
    num_cc_transactions INTEGER;
    total_cc_transaction_amounts INTEGER;
    fee_months INTEGER := 0;

    -- Declare a cursor to fetch all rows
    cursor_name CURSOR FOR
        WITH months AS (
            SELECT 
                generate_series(
                    '2020-01-01'::DATE,
                    '2020-12-01'::DATE,
                    INTERVAL '1 month'
                ) AS month
        )
        SELECT 
            TO_CHAR(month, 'YYYY-MM') AS month,
            COALESCE(SUM(amount),0) AS balance,
            COALESCE(SUM(CASE WHEN amount < 0 THEN 1 ELSE 0 END), 0) AS cc_transactions,
            COALESCE(SUM(CASE WHEN amount < 0 THEN amount ELSE 0 END), 0) AS total_cc_transactions
        FROM 
            months
        LEFT JOIN 
            transactions ON DATE_TRUNC('month', transactions.date) = months.month
        GROUP BY 
            months.month
        ORDER BY 
            months.month;
BEGIN
    OPEN cursor_name;
    LOOP
        FETCH NEXT FROM cursor_name INTO month_value, balance_value, num_cc_transactions, total_cc_transaction_amounts;
        
        EXIT WHEN NOT FOUND;
        -- RAISE NOTICE 'Month % has a balance of % and % CC transactions totaling %.', month_value, balance_value, num_cc_transactions, ABS(total_cc_transaction_amounts);
        -- RAISE NOTICE '  Start of month total balance: %', total_balance;

        fee_months := fee_months + 1;

        IF num_cc_transactions >= 3 AND ABS(total_cc_transaction_amounts) >= 100 THEN
            -- RAISE NOTICE '    *** No fee charged in %', month_value;
            fee_months := fee_months - 1;
        END IF;

        total_balance := total_balance + balance_value;
        -- RAISE NOTICE '  End of month total balance: %, fee months %', total_balance, fee_months;

    END LOOP;
    CLOSE cursor_name;
    RETURN total_balance - (5 * fee_months);
END;
$$ LANGUAGE plpgsql;


SELECT * FROM fetch_and_process_transactions() AS "balance";