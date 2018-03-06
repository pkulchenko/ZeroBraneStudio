---
layout: default
title: Lua Quick Start Guide
---

This is a **Quick Start Guide for Lua** based on the [Lua manual](http://www.lua.org/manual/5.1/manual.html).
If you use it with ZeroBrane Studio, you can copy it into a new editor
window and will be able to run it and can click on links to read
corresponding sections in the manual.

```lua

-- This is a one-line comment that ends at the end of the line
--[[ This a multi-line (long) [comment](http://www.lua.org/manual/5.1/manual.html#2.1)
     that ends with this closing bracket --> ]]
--[=[ This is also a long comment ]=]

-- [Numbers](http://www.lua.org/manual/5.1/manual.html#2.1)
hours = 54
regularRate = 16

-- [Arithmetic operators](http://www.lua.org/manual/5.1/manual.html#2.5.1)
-- `+` (addition), `-` (subtraction), `*` (multiplication), `/` (division), 
-- `%` (modulo), `^` (exponentiation), and unary `-` (negation)
overtimeRate = regularRate * 1.5
totalPay = 40 * regularRate + (hours-40) * overtimeRate

-- [Relational operators](http://www.lua.org/manual/5.1/manual.html#2.5.2)
-- `==` (equal), `~=` (not equal), `<` (less), `>` (more), 
-- `<=` (less or equal), and `>=` (more or equal)
-- these operators always result in `false` and `true`.
isOvertime = hours > 40
isTheSame = 
  math.min(regularRate, overtimeRate) == -math.max(-regularRate, -overtimeRate)

-- [Logical operators](http://www.lua.org/manual/5.1/manual.html#2.5.3): `and`, `or`, and `not`
-- The conjunction operator `and` returns its first argument if this value is `false` or `nil`;
-- otherwise, `and` returns its second argument.
-- The disjunction operator `or` returns its first argument if this value is different from `nil`
-- and `false`; otherwise, `or` returns its second argument.
-- Both `and` and `or` use short-cut evaluation: the second operand is evaluated only if needed.
a = 10 or 20 --> 10
a = 10 or 'something else' --> 10
a = 10 and 20 --> 20
a = false and 10 --> false

-- [Strings](http://www.lua.org/manual/5.1/manual.html#2.1)
firstName = 'Paul'
lastName = "Kulchenko"
escapedDoubleQuote = "She said: \"You shouldn't be doing this\""
stringWithQuotes = [[She said: "You shouldn't be doing this"]]
-- \\ escapes the slash itself; \n encodes a new line
moreEscapes = 'She said:\n\"You shouldn\'t be doing\\ this\"'

-- [Concatenation](http://www.lua.org/manual/5.1/manual.html#2.5.4)
fullName = firstName .. ' ' .. lastName --> Paul Kulchenko

-- [Formatting](http://www.lua.org/manual/5.1/manual.html#pdf-string.format)
message = ('The payment amount for %s is %d'):format(fullName, totalPay)

-- Placeholders
-- %d placeholder is for integer numbers
print(("%d"):format(5)) --> 5
-- %s placeholder is for strings
print(("%s"):format('string')) --> string
-- %f placeholder is for real numbers
print(("%.2f"):format(1.5)) --> 1.50
-- `.2` in `%.2f` specifies the number of decimal digits to be printed
-- %.0f placeholder truncates real numbers
print(("%.0f"):format(1.5)) --> 1

-- [Patterns and Captures](http://www.lua.org/manual/5.1/manual.html#5.4.1)
local text = '21.12,24.16,"-1.1%"'
-- match one digit
print(string.match(text, '%d')) --> 2
-- match one or more digits
print(string.match(text, '%d+')) --> 21
-- match a (real) number with an optional minus
print(string.match(text, '%-?%d[%.%d]*')) --> 21.12
-- match and captures two numbers separated by a comma
print(string.match(text, '(%-?%d[%.%d]*),(%-?%d[%.%d]*)')) --> 21.12 24.16

-- **Output**
print(message) -- the output also includes a new line
print("The payment amount is " .. totalPay)
print() -- this prints an empty line

-- **Input** ([io.read](http://www.lua.org/manual/5.1/manual.html#pdf-file:read))
print("What is your name? ")
name = io.read() -- reads one line
print("What is your age? ")
age = io.read('*n') -- reads one number ignoring whitespaces
print("You've entered " ..  name .. ' and ' .. age)

-- [Function call](http://www.lua.org/manual/5.1/manual.html#2.5.8)
result = math.max(overtimeRate, regularRate) -- this function returns one result
print(result) -- the function `print` doesn't return any results

-- [Function definition](http://www.lua.org/manual/5.1/manual.html#2.5.9)
function myfunction(arguments) -- this function takes one parameter
  -- body of the function
  return 1, 2, 3 -- this function returns three values
end

-- [Identifiers](http://www.lua.org/manual/5.1/manual.html#2.1)
-- Identifier is any string of letters, digits, and underscores, not beginning with a digit.
-- Identifiers (also called names) are used to name variables and table fields.
-- Lua keywords (`if`, `local`, `do`, and others) are reserved and cannot be used as names.

-- [Variables](http://www.lua.org/manual/5.1/manual.html#2.3)
-- Variables are places that store values.
-- There are three kinds of variables in Lua: global variables, local variables, and table fields.

-- [Assignment](http://www.lua.org/manual/5.1/manual.html#2.4.3)
-- multiple variables localized
local a, b = 1, 2
-- this is the same as
local a = 1
local b = 2

-- swapping two variables
local a, b = b, a

-- assigning multiple values returned by a function
local a, b, c = myfunction() -- assigns 1, 2, 3 to a, b, c

-- [Scope and visibility rules](www.lua.org/manual/5.1/manual.html#2.6)
-- The scope of variables begins at the first statement after their declaration
-- and lasts until the end of the innermost block that includes the declaration.
x = 10                -- global variable
do                    -- new block
  local x = x         -- new 'x', with value 10
  print(x)            --> 10
  x = x+1
  do                  -- another block
    local x = x+1     -- another 'x'
    print(x)          --> 12
  end
  print(x)            --> 11
end
print(x)              --> 10  (the global one)

-- **Selection** ([if](http://www.lua.org/manual/5.1/manual.html#2.4.4) statement)
-- Both `false` and `nil` are considered false; all other values are considered true
-- (in particular, the number 0 and the empty string are also true).
if hours > 40 then
  print("You've had some overtime this week!")
else
  print("You have no overtime this week")
end

-- **for Loop** ([for](http://www.lua.org/manual/5.1/manual.html#2.4.5) statement)
for i = 1,2 do
  greeting = i == 1 and 'Hello' or 'Bye'
  print(greeting, name)
end

-- **while Loop** ([while](http://www.lua.org/manual/5.1/manual.html#2.4.4) statement)
print("Enter a number; enter 0 to end the sequence")
local num = tonumber(io.read("*n"))
while num ~= 0 do
  print(num)
  num = tonumber(io.read("*n"))
end

-- [Table](http://www.lua.org/manual/5.1/manual.html#2.5.7)
payByWeek = {320, 540, 340, 880}
payByPerson = {John = 320, Mary = 340, Bob = 880, Rob = 860}

-- iterate over array part
for week, pay in ipairs(payByWeek) do
  print("Paid "..pay.." in week "..week)
end

-- iterate over hash part (no guaranteed order)
for person, pay in pairs(payByPerson) do
  print("Paid "..pay.." to "..person)
end

-- test if a key is present in the table
-- `payByPerson['John']` is the same as `payByPerson.John`
if payByPerson['John'] then
  print('John has been paid this week')
end

-- getting random values
local M, N = 10, 20
math.random() -- returns a real value in the range [0, 1)
math.random(M) -- returns an integer value in the range [1, M]
math.random(M, N) -- returns an integer value in the range [M, N]
math.randomseed(os.time()) -- "seeds" pseudo-random generator
-- using the same seed will produce the same sequence

```
