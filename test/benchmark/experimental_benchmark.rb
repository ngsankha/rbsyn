# synthetic: true
require "test_helper"

describe "Synthesis Benchmark" do
  it "experiment" do
    define :update_post, "(String, String, {created_by: ?String, title: ?String, slug: ?String}) -> Post", [Post, DemoUser], prog_size: 40 do
      # spec "admin can takeover any post" do
      #   pre {
      #     @dummy = DemoUser.create(name: 'Dummy', username: 'dummy', admin: false)
      #     @admin = DemoUser.create(name: 'Admin', username: 'admin', admin: true)
      #     @author = DemoUser.create(name: 'Author', username: 'author', admin: false)
      #     @fake_post = Post.create(created_by: 'dummy', slug:'fake-post', title: 'Fake Post')
      #     @post = Post.create(created_by: 'author', slug:'hello-world', title: 'Hello World')
      #   }

      #   updated = update_post('admin', 'hello-world', created_by: 'dummy', title: 'Foo Bar', slug: 'foo-bar')

      #   post { |updated|
      #     assert { updated.id == @post.id }
      #     assert { updated.created_by == "dummy" }
      #     assert { updated.title == "Foo Bar" }
      #     assert { updated.slug == 'foo-bar' }
      #   }
      # end

      spec "author can only change titles" do
        pre {
          @dummy = DemoUser.create(name: 'Dummy', username: 'dummy', admin: false)
          @admin = DemoUser.create(name: 'Admin', username: 'admin', admin: true)
          @author = DemoUser.create(name: 'Author', username: 'author', admin: false)
          @fake_post = Post.create(created_by: 'dummy', slug:'fake-post', title: 'Fake Post')
          @post = Post.create(created_by: 'author', slug:'hello-world', title: 'Hello World')
        }

        updated = update_post('author', 'hello-world', created_by: 'dummy', title: 'Foo Bar', slug: 'foo-bar')

        post { |updated|
          assert { updated.id == @post.id }
          assert { updated.created_by == "author" }
          assert { updated.title == "Foo Bar" }
          assert { updated.slug == 'hello-world' }
        }
      end

      spec "unrelated users cannot change anything" do
        pre {
          @dummy = DemoUser.create(name: 'Dummy', username: 'dummy', admin: false)
          @admin = DemoUser.create(name: 'Admin', username: 'admin', admin: true)
          @author = DemoUser.create(name: 'Author', username: 'author', admin: false)
          @fake_post = Post.create(created_by: 'dummy', slug:'fake-post', title: 'Fake Post')
          @post = Post.create(created_by: 'author', slug:'hello-world', title: 'Hello World')
        }

        updated = update_post('dummy', 'hello-world', created_by: 'dummy', title: 'Foo Bar', slug: 'foo-bar')

        post { |updated|
          assert { updated.id == @post.id }
          assert { updated.created_by == "author" }
          assert { updated.title == "Hello World" }
          assert { updated.slug == 'hello-world' }
        }
      end

      puts generate_program
    end
  end
end
