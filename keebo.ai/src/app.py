#!/usr/bin/env python
import os

VAL = os.getenv("FOO", "foo")

def bar(*args, **kwargs):
    for arg in args:
      print(f"the value of arg is {arg}\n")

    for key, value in kwargs.items():
      print(f"Key: {key}, Value: {value}")

if __name__ == "__main__":
  print(f"hello from python, the value of FOO is {VAL}")
  some_list = [ "a", "b", "c"]
  bar(*some_list)

  blah = { "foo": "foo1"}
  bar(None,**blah)