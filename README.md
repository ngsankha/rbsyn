# Rbsyn ![](https://github.com/ngsankha/rbsyn/workflows/Rbsyn%20Build/badge.svg)

Program synthesis for Ruby.

Given a function specification in the form of tests and type annotations with [RDL](https://github.com/tupl-tufts/rdl), this synthesizes a Ruby function that would pass the tests. This reduces programmer effort to just writing tests that specify the function behavior and the computer writing the function implementation for you.

## Installation

You need a working Ruby installation with [Bundler](https://bundler.io/) installed. Then install all the dependencies by executing `bundle install`.

## Using Rbsyn

Rbsyn specifications are written in a similar fashion as unit tests in a domain specific language.

You start off by defining a function you want to specify:

```ruby
define :foo, "(String) -> %bool" do
  # ...
end
```

The first argument is the name of function, and the second argument is the function signature. Inside this block you can now write the unit tests for this function. A unit test is of the following form:

```ruby
spec "returns true if some condition is met" do
  pre {
    # the code that makes that condition true
  }

  foo("argument to my function")

  post { |result|
    result == true
  }
end
```

The actual function call is preceded by a `pre` block that does the setup necessary to execute the function under test. The following line actually executes the function for which we are writing a test. The `post` block comes at the end. This is like a post condition - this blokc should return true if the test passes all assertions, false otherwise.

### Example

Let us take a look at a complete example that defines and generates the `username_available?` function by querying the database.

```ruby
define :username_available?, "(String) -> %bool" do

  spec "returns true when user doesn't exist" do
    username_available? 'bruce1'

    post { |result|
      result == true
    }
  end

  spec "returns false when user exists" do
    pre {
      u = User.create(name: 'Bruce Wayne', username: 'bruce1', password: 'coolcool')
      u.emails.create(email: 'bruce1@wayne.com')
    }

    username_available? 'bruce1'

    post { |result|
      result == false
    }
  end

  puts generate_program
end
```

This should print the following program to the console:

```ruby
def username_available?(arg0)
  User.exists?(username: arg0)
end
```

## Tests

You can run the unit tests and the sample benchmarks by executing `bundle exec rake`.

All the unit tests are in [`test/unit`](test/unit) and the benchmarks can be found in [`test/benchmark`](test/benchmark).
