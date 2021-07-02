<img align="left" src="rbsyn-logo.png" width=110>

# Rbsyn

Program synthesis for Ruby, guided by type and effect annotations. See the [PLDI 2021](https://arxiv.org/abs/2102.13183) paper for more details on the approach.

Given a method specification in the form of tests, type and effect annotations with [RDL](https://github.com/tupl-tufts/rdl), this synthesizes a Ruby function that will pass the tests. This reduces programmer effort to just writing tests that specify the function behavior and the computer writing the function implementation for you.

## Installation

You need a working Ruby installation with [Bundler](https://bundler.io/) installed. Then install all the dependencies by executing `bundle install`.

We have tested RbSyn on Ruby 2.6.3 with Bundler 2.1.4. Other versions should work, but we have not tested it. Let us know if there are any issues.

## Running Tests

All the benchmark programs can be run using the following command:

```
bundle exec rake bench
```

Prefix the environment variable `CONSOLE_LOG=1` to the above command to print the synthesized method. To run a single test use the following command:

```
bundle exec rake bench TEST=<path-to-test-file>
```

All the benchmarks can be found in [`test/benchmark`](test/benchmark) and custom benchmarks can be run by updating in [`Rakefile`](Rakefile) in line 15, for the `t.test_files` value.

## Environment Variables

Multiple flags can be passed to RbSyn to explore different configurations of synthesis:

* `CONSOLE_LOG=1`: Print the programs that are bring synthesized.
* `DISABLE_TYPES=1`: Disable type directed synthesis.
* `DISABLE_EFFECTS=1`: Disable effect guided synthesis.
* `EFFECT_PREC=0` or `EFFECT_PREC=1` or `EFFECT_PREC=2`: Set the level of effect precision to use. 0 is the most precise, 1 is class level precision and 2 reduces annotations to pure or impure only.

These environment variables can be passed in any combination in the bench command like so:

```
CONSOLE_LOG=1 DISABLE_EFFECTS=1 bundle exec rake bench
```

## Using RbSyn

You can try to play with the implementation of RbSyn, the purpose of some of the key modules are given in the file structure section above.

To write a new test, you can either copy an example from the existing benchmark and modify it. Update the `Rakefile` so the `t.test_files` contain your new benchmark.

Benchmarks follow roughly this format:

```
# type definitions for methods that will be used for synthesis
RDL.type Array, :first, '() -> t', wrap: false

define :username_available?, "(String) -> %bool" do

  spec "returns true when user doesn't exist" do
    username_available? 'bruce1'

    post { |result|
      result == true
    }
  end

  spec "returns false when user exists" do
    setup {
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

By default RbSyn will only use "" (empty string), 0 and 1 for constants during synthesis. To include some other constants in this set, add them to `lib/rbsyn/context.rb` lines 26 and 27.

`nil` is not synthesized by default, to enable the synthesis of `nil` set the option `enable_nil: true`. For an example see, `test/benchmark/diaspora/user_confirm_email_benchmark.rb`.

## Issues, questions or comments?

Please file an issue on Github if you have problem running RbSyn. Feel free to send an email to sankha@cs.umd.edu.

---

_Logo derived from icon by [ultimatearm](https://www.flaticon.com/authors/ultimatearm) from [www.flaticon.com](https://www.flaticon.com/)._

