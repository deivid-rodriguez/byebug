# frozen_string_literal: true

require "open3"

Open3.capture2e("git", "status", stdin_data: "")
