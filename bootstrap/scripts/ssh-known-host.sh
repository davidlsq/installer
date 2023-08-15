#!/bin/bash

echo "$2 $(cat "$1.pub")" >> "$3"
