return {
  "rgroli/other.nvim",
  config = function()
    local rails_alternative_targets = {
      {
        context = "model",
        target = "/app/models/%1.rb",
        transformer = "singularize",
      },
      {
        context = "controller",
        target = "/app/controllers/**/%1_controller.rb",
      },
      { context = "view", target = "/app/views/%1/*.html*" },
      {
        context = "view",
        target = "/app/views/%1/*.html*",
        transformer = "singularize",
      },
      {
        context = "channel",
        target = "/app/channels/**/%1_channel.rb",
      },
      { context = "mailer", target = "/app/mailers/%1_mailer.rb" },
      {
        context = "serializer",
        target = "/app/serializers/%1_serializer.rb",
      },
      { context = "mailer", target = "/app/mailers/%1_mailer.rb" },
      { context = "service", target = "/app/services/%1_service.rb" },
      { context = "worker", target = "/app/workers/**/%1_worker.rb" },
      {
        context = "factories",
        target = "/spec/factories/%1.rb",
        transformer = "singularize",
      },
    }

    local is_rspec = vim.fn.isdirectory(vim.fn.getcwd() .. "/spec")

    local main_targets = is_rspec
        and {
          { context = "test", target = "/spec/%1/%2_spec.rb" },
          { context = "test", target = "/spec/%2_spec.rb" },
          { context = "test", target = "/spec/%1/%2_spec.rb" },
          { context = "test", target = "/spec/%2_spec.rb" },
          {
            context = "test",
            target = "/spec/functional/%1/%2_spec.rb",
          },
          {
            context = "test",
            target = "/spec/functional/%2_spec.rb",
          },
          {
            context = "test",
            target = "/spec/functional/**/%2_spec.rb",
          },
          {
            context = "test",
            target = "/spec/integration/%1/%2_spec.rb",
          },
          {
            context = "test",
            target = "/spec/integration/%2_spec.rb",
          },
          {
            context = "test",
            target = "/spec/integration/**/%2_spec.rb",
          },
        }
      or {
        { context = "test", target = "/test/functional/%1/%2_test.rb" },
        { context = "test", target = "/test/functional/%2_test.rb" },
        { context = "test", target = "/test/functional/**/%2_test.rb" },
        {
          context = "test",
          target = "/test/integration/%1/%2_test.rb",
        },
        { context = "test", target = "/test/integration/%2_test.rb" },
        {
          context = "test",
          target = "/test/integration/**/%2_test.rb",
        },
        { context = "test", target = "/test/%1/%2_test.rb" },
        { context = "test", target = "/test/%2_test.rb" },
        { context = "test", target = "/test/%1/%2_test.rb" },
        { context = "test", target = "/test/%2_test.rb" },
      }

    local rails_mappings = {
      {
        pattern = "/app/(.*)/(.*).rb",
        target = main_targets,
      },
      -- going back to source from tests
      {
        pattern = "(.+)/test/(.*)/(.*)/(.*)_test.rb",
        target = {
          { target = "%1/db/%3/%4.rb" },
          { target = "%1/app/%3/%4.rb" },
          { target = "%1/%3/%4.rb" },
        },
      },
      {
        pattern = "(.+)/test/(.*)/(.*)_test.rb",
        target = {
          { target = "%1/db/%2/%3.rb" },
          { target = "%1/app/%2/%3.rb" },
          { target = "%1/lib/%2/%3.rb" },
        },
      },
      {
        pattern = "(.+)/test/(.*)/(.*)_(.*)_test.rb",
        target = {
          { target = "%1/app/%4s/%3_%4.rb" },
        },
      },
      -- Additional mappings per filetype
      {
        pattern = "/app/controllers/(.*)_controller.rb",
        target = rails_alternative_targets,
      },
      {
        pattern = "/app/views/(.*)/.+.html*",
        target = rails_alternative_targets,
      },
      {
        pattern = "/app/models/(.*).rb",
        target = rails_alternative_targets,
      },
      {
        pattern = "/app/channels/(.*)_channel.rb",
        target = rails_alternative_targets,
      },
      {
        pattern = "/app/mailers/(.*)_mailer.rb",
        target = rails_alternative_targets,
      },
      {
        pattern = "/app/serializers/(.*)_serializer.rb",
        target = rails_alternative_targets,
      },
      {
        pattern = "/app/services/(.*)_service.rb",
        target = rails_alternative_targets,
      },
      {
        pattern = "/app/workers/(.*)/(.*)_worker.rb",
        target = rails_alternative_targets,
      },
    }

    local mappings = {
      "golang",
      {
        pattern = "(.+)/spec/(.*)/(.*)/(.*)_spec.rb",
        target = {
          { target = "%1/db/%3/%4.rb" },
          { target = "%1/app/%3/%4.rb" },
          { target = "%1/%3/%4.rb" },
        },
      },
      {
        pattern = "(.+)/spec/(.*)/(.*)_spec.rb",
        target = {
          { target = "%1/db/%2/%3.rb" },
          { target = "%1/app/%2/%3.rb" },
          { target = "%1/lib/%2/%3.rb" },
        },
      },
      {
        pattern = "(.+)/spec/(.*)/(.*)_(.*)_spec.rb",
        target = {
          { target = "%1/app/%4s/%3_%4.rb" },
        },
      },
    }

    for i = 1, #rails_mappings do
      ---@diagnostic disable-next-line: assign-type-mismatch
      mappings[#mappings + 1] = rails_mappings[i]
    end

    require("other-nvim").setup({
      mappings = mappings,
    })

    vim.api.nvim_set_keymap("n", "<leader>ll", "<cmd>:Other<CR>", { noremap = true, silent = true })
    vim.api.nvim_set_keymap(
      "n",
      "<leader>ls",
      "<cmd>:OtherSplit<CR>",
      { noremap = true, silent = true }
    )
    vim.api.nvim_set_keymap(
      "n",
      "<leader>lv",
      "<cmd>:OtherVSplit<CR>",
      { noremap = true, silent = true }
    )
  end,
}
