#!/usr/bin/env python
import os

VAL = os.getenv("FOO", "foo")

print(f"hello from python, the value of FOO is {VAL}")