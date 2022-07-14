# disabled last test because no way to test it

require "test_helper"

describe "Diaspora" do
  it "pod#schedule_check_if_needed" do
    load_typedefs :stdlib, :ar_update

    RDL.type DiasporaPod, 'self.status_codes', '() -> { unchecked: Integer, no_errors: Integer, net_failed: Integer }', wrap: false
    RDL.type Integer, :!=, '(Integer) -> %bool', wrap: false
    RDL.type Integer, :==, '(Integer) -> %bool', wrap: false

    define :schedule_check_if_needed, "(DiasporaPod) -> %bool", [DiasporaPod], prog_size: 50 do
      spec "schedules the pod for the next check if it is offline" do
        setup {
          @pod = Fabricate(:pod, status: :net_failed)
          schedule_check_if_needed(@pod)
        }

        post { |result|
          assert { !!@pod.reload.scheduled_check == true}
        }
      end

      spec "does nothing if the pod unchecked" do
        setup {
          @pod = Fabricate(:pod)
          schedule_check_if_needed(@pod)
        }

        post { |result|
          assert { !!@pod.scheduled_check == false }
        }
      end

      spec "does nothing if the pod is online" do
        setup {
          @pod = Fabricate(:pod, status: :no_errors)
          schedule_check_if_needed(@pod)
        }

        post { |result|
          assert { !!@pod.scheduled_check == false }
        }
      end

      # spec "does nothing if the pod is scheduled for the next check" do
      #   setup {
      #     @pod = Fabricate(:pod, status: :no_errors, scheduled_check: true)
      #     @old_updated = @pod.updated_at
      #     schedule_check_if_needed(@pod)
      #   }

      #   post { |result|
      #     assert { @pod.updated_at == @old_updated }
      #   }
      # end

      generate_program
    end
  end
end
