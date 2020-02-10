# synthetic: true
require "test_helper"

describe "Synthesis Benchmark" do
  it "overview example" do
    define :update_post, "(String, String, {created_by: ?String, title: ?String, slug: ?String}) -> Post", [Post, DemoUser], prog_size: 30, max_hash_size: 2 do
      spec "author can only change titles" do
        pre {
          @dummy = DemoUser.create(name: 'Dummy', username: 'dummy', admin: false)
          @admin = DemoUser.create(name: 'Admin', username: 'admin', admin: true)
          @author = DemoUser.create(name: 'Author', username: 'author', admin: false)
          @fake_post = Post.create(created_by: 'dummy', slug: 'fake-post', title: 'Fake Post')
          @fake_post2 = Post.create(created_by: 'dummy', slug: 'fake-post2', title: 'Fake Post 2')
          @admin_post = Post.create(created_by: 'admin', slug: 'admin-post', title: 'Admin Post')
          @admin_post2 = Post.create(created_by: 'admin', slug: 'admin-post2', title: 'Admin Post 2')
          @post2 = Post.create(created_by: 'author', slug: 'hello-world2', title: 'Hello World 2')
          @post = Post.create(created_by: 'author', slug: 'hello-world', title: 'Hello World')
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
          @fake_post = Post.create(created_by: 'dummy', slug: 'fake-post', title: 'Fake Post')
          @fake_post2 = Post.create(created_by: 'dummy', slug: 'fake-post2', title: 'Fake Post 2')
          @admin_post = Post.create(created_by: 'admin', slug: 'admin-post', title: 'Admin Post')
          @admin_post2 = Post.create(created_by: 'admin', slug: 'admin-post2', title: 'Admin Post 2')
          @post2 = Post.create(created_by: 'author', slug: 'hello-world2', title: 'Hello World 2')
          @post = Post.create(created_by: 'author', slug: 'hello-world', title: 'Hello World')
        }

        updated = update_post('dummy', 'hello-world', created_by: 'dummy', title: 'Foo Bar', slug: 'foo-bar')

        post { |updated|
          assert { updated.id == @post.id }
          assert { updated.created_by == "author" }
          assert { updated.title == "Hello World" }
          assert { updated.slug == 'hello-world' }
        }
      end

      spec "admin can takeover any post" do
        pre {
          @dummy = DemoUser.create(name: 'Dummy', username: 'dummy', admin: false)
          @admin = DemoUser.create(name: 'Admin', username: 'admin', admin: true)
          @author = DemoUser.create(name: 'Author', username: 'author', admin: false)
          @fake_post = Post.create(created_by: 'dummy', slug: 'fake-post', title: 'Fake Post')
          @fake_post2 = Post.create(created_by: 'dummy', slug: 'fake-post2', title: 'Fake Post 2')
          @admin_post = Post.create(created_by: 'admin', slug: 'admin-post', title: 'Admin Post')
          @admin_post2 = Post.create(created_by: 'admin', slug: 'admin-post2', title: 'Admin Post 2')
          @post2 = Post.create(created_by: 'author', slug: 'hello-world2', title: 'Hello World 2')
          @post = Post.create(created_by: 'author', slug: 'hello-world', title: 'Hello World')
        }

        updated = update_post('admin', 'hello-world', created_by: 'dummy', title: 'Foo Bar', slug: 'foo-bar')

        post { |updated|
          assert { updated.id == @post.id }
          assert { updated.created_by == "dummy" }
          assert { updated.title == "Foo Bar" }
          assert { updated.slug == 'foo-bar' }
        }
      end

      assert_equal generate_program, %{
def update_post(arg0, arg1, arg2)
  if DemoUser.exists?(username: arg0, admin: false)
    if Post.exists?(created_by: arg0, slug: arg1)
      t2 = Post.where(slug: arg1).first
      t2.title=arg2.[](:title)
      t2
    else
      Post.where(slug: arg1).first
    end
  else
    t4 = Post.where(slug: arg1).first
    t4.created_by=arg2.[](:created_by)
    t4.title=arg2.[](:title)
    t4.slug=arg2.[](:slug)
    t4
  end
end
}.strip
    end
  end
end
