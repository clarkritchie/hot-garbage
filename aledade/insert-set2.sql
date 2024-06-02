drop table transactions;

create table transactions (
    amount integer not null,
    date date not null
);

insert into transactions values ('1', '2020-06-29');
insert into transactions values ('35', '2020-02-20');
insert into transactions values ('-50', '2020-02-03');
insert into transactions values ('-1', '2020-02-26');
insert into transactions values ('-200', '2020-08-01');
insert into transactions values ('-44', '2020-02-07');
insert into transactions values ('-5', '2020-02-25');
insert into transactions values ('1', '2020-06-29');
insert into transactions values ('1', '2020-06-29');
insert into transactions values ('-100', '2020-12-29');
insert into transactions values ('-100', '2020-12-30');
insert into transactions values ('-100', '2020-12-31 ');