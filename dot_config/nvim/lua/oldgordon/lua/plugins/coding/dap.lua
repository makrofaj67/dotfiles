return {

	"mfussenegger/nvim-dap",

	dependencies = {

		"rcarriga/nvim-dap-ui",

		"nvim-neotest/nvim-nio",

		"williamboman/mason.nvim",
		"jay-babu/mason-nvim-dap.nvim",

		"leoluz/nvim-dap-go",
	},
	keys = {

		{
			"<F1>",
			function()
				require("dap").step_into()
			end,
			desc = "Debug: Step Into",
		},

		{
			"<F5>",
			function()
				local file_path = vim.fn.expand("%:p")
				local input = vim.fn.input("Run with args (file_path args): ", file_path .. " ")
				local parts = vim.split(input, " ", { trimempty = true })

				local target_file = parts[1]
				table.remove(parts, 1)
				local args = parts

				local dap = require("dap")

				if vim.bo.filetype == "c" then
					local output_path = vim.fn.fnamemodify(target_file, ":p:r")

					local compile_cmd = string.format("gcc -g %s -o %s", target_file, output_path)
					local compile_result = vim.fn.system(compile_cmd)

					if vim.v.shell_error ~= 0 then
						vim.notify("Compilation failed: " .. compile_result, vim.log.levels.ERROR)
						return
					end

					dap.run({
						type = "cppdbg",
						request = "launch",
						program = output_path,
						args = args,
						cwd = vim.fn.getcwd(),
						stopOnEntry = true,
						setupCommands = {
							{
								description = "enable pretty printing",
								text = "-enable-pretty-printing",
								ignoreFailures = false,
							},
						},
					})
				elseif vim.bo.filetype == "go" then
					dap.run({
						type = "delve",
						name = "Debug with args",
						request = "launch",
						program = target_file,
						args = args,
					})
				else
					vim.notify("Debugging not configured for this filetype: " .. vim.bo.filetype, vim.log.levels.ERROR)
				end
			end,
			desc = "Debug: Start/Continue with Args",
		},
		{
			"<F2>",
			function()
				require("dap").step_over()
			end,
			desc = "Debug: Step Over",
		},
		{
			"<F3>",
			function()
				require("dap").step_out()
			end,
			desc = "Debug: Step Out",
		},
		{
			"<leader>bb",
			function()
				require("dap").toggle_breakpoint()
			end,
			desc = "Debug: Toggle Breakpoint",
		},
		{
			"<leader>bB",
			function()
				require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
			end,
			desc = "Debug: Set Breakpoint",
		},

		{
			"<F7>",
			function()
				require("dapui").toggle()
			end,
			desc = "Debug: See last session result.",
		},
	},
	config = function()
		local dap = require("dap")
		local dapui = require("dapui")

		require("mason").setup()
		require("mason-nvim-dap").setup({
			ensure_installed = { "cpptools", "delve" },
			automatic_installation = true,
			handlers = {
				function(config)
					require("mason-nvim-dap").default_setup(config)
				end,
			},
		})

		dap.adapters.cppdbg = {
			id = "cppdbg",
			type = "executable",
			command = vim.fn.stdpath("data") .. "/mason/packages/cpptools/extension/debugAdapters/bin/OpenDebugAD7",
		}

		dap.configurations.c = {
			{
				name = "Launch file",
				type = "cppdbg",
				request = "launch",
				program = function()
					return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
				end,
				cwd = "${workspaceFolder}",
				stopOnEntry = true,
				setupCommands = {
					{
						description = "enable pretty printing",
						text = "-enable-pretty-printing",
						ignoreFailures = false,
					},
				},
			},
		}

		dapui.setup({

			icons = { expanded = "▾", collapsed = "▸", current_frame = "*" },
			controls = {
				icons = {
					pause = "⏸",
					play = "▶",
					step_into = "⏎",
					step_over = "⏭",
					step_out = "⏮",
					step_back = "b",
					run_last = "▶▶",
					terminate = "⏹",
					disconnect = "⏏",
				},
			},
		})

		dap.last_args = {}
		dap.listeners.after.event_initialized["dapui_config"] = dapui.open
		dap.listeners.before.event_terminated["dapui_config"] = dapui.close
		dap.listeners.before.event_exited["dapui_config"] = dapui.close

		require("dap-go").setup({
			delve = {

				detached = vim.fn.has("win32") == 0,
			},
		})
	end,
}