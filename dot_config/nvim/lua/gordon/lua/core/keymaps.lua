local map = vim.keymap.set

-- Kod Satirlarini Asagi Yuxari Tasi (Ide Stili - C++'ta mukemmel calisir)
map("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Asagi Tasi" })
map("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Yukari Tasi" })
map("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Asagi Tasi" })
map("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Yukari Tasi" })
map("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Asagi Tasi" })
map("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Yukari Tasi" })

-- Acik Bufferlar/Sekmeler Arasi Hizli Gecis 
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Onceki Sekme" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Sonraki Sekme" })

-- Pencereler (Splitler) Arasi Ozel Gecis
map("n", "<C-h>", "<C-w>h", { desc = "Sol Pencereye Gec" })
map("n", "<C-j>", "<C-w>j", { desc = "Alt Pencereye Gec" })
map("n", "<C-k>", "<C-w>k", { desc = "Ust Pencereye Gec" })
map("n", "<C-l>", "<C-w>l", { desc = "Sag Pencereye Gec" })

-- Modern ve Hizli Kaydet / Cik
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Dosyayi Kaydet" })
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Dosyayi Kaydet" })
map("n", "<leader>q", "<cmd>q<cr>", { desc = "Cikis" })

-- Arama Sonrasi Sararan Vurguyu Esc Ile Temizle
map({ "i", "n" }, "<esc>", "<cmd>noh<cr><esc>", { desc = "Arama Vurgusunu Kaldir" })
