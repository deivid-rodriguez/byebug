Thanks for your interest in contributing to ByeBug!

To make your changes, follow this steps:

* [Fork the project](https://help.github.com/fork-a-repo)
* Create a topic branch - `git checkout -b my_branch`
* Insert awesome code - See below
* Push your branch to your forked repo - `git push origin my_branch`
* [Make a pull request](https://help.github.com/articles/using-pull-requests)

How to insert awesome code:

This gem uses `rake-compiler` to build native gems. You can use `rake compile` to build the native gem
and start the tests using `rake test`

```bash
rake compile
rake test
```

It's appreciated if you add tests for new functionality. Thanks!