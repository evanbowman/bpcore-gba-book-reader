txtr(0, "overlay.bmp")


local pg_color = 0xf0eddf
local text_color = 0x2f264e


fade(1, pg_color, true, false)


book_data, book_len = file("book.txt")


local page = 0
local read_index = 0


-- Note about load_offset/store_offset: We need to be able to backtrack to
-- previous pages, which is much simpler if we store the byte offset of the
-- beginning of the page each time we load a new one.
function store_index()
   poke4(_IRAM + page * 4, read_index)
end


function load_index(pg)
   return peek4(_IRAM + pg * 4)
end


function read_char()
   local value = string.char(peek(book_data + read_index))
   read_index = read_index + 1
   return value
end


function is_delimiter(chr)
   return chr == " " or chr == "\n"
end


function read_word()
   local word = ""
   local delim = ""
   while true do
      local chr = read_char()
      if chr ~= "\r" then
         if is_delimiter(chr) then
            return word, delim .. chr
         end
         word = word .. chr
      else
         delim = delim .. chr
      end
   end
end


local x_write = 1
local y_write = 2


function handle_delimiter(delim, print_fn)
   if delim == "\n" or delim == "\r\n" then
      y_write = y_write + 2
      x_write = 1
   elseif delim == " " then
      print_fn(delim, x_write, y_write)
      x_write = x_write + 1
   end
end


function load_page(pg, print_fn)

   page = pg

   store_index()


   local page_num = tostring(pg + 1)
   print_fn(page_num, (29 - string.len(page_num)), 18)
   -- print(page_num,  , text_color, pg_color)


   x_write = 1
   y_write = 1

   while true do
      word, delim = read_word()

      if y_write >= 17 then
         return
      end

      local word_len = utf8.len(word)
      if word_len + x_write > 28 then
         x_write = 1
         y_write = y_write + 2

         if y_write >= 17 then
            -- We ran out of room, subtract the read-offset by the length of the
            -- last processed word.
            read_index = read_index - (string.len(word) + string.len(delim))
            return
         end
      end

      print_fn(word, x_write, y_write)
      x_write = x_write + word_len

      handle_delimiter(delim, print_fn)
   end
end


function active_print_fn(str, x, y)
   print(str, x, y, text_color, pg_color)
end


function void_print_fn(str, x, y)
   -- Do nothing...
end


load_page(0, active_print_fn)


print(tostring(collectgarbage("count") * 1024), 0, 19, text_color, pg_color)


while true do
   clear()

   if btnp(4) and page > 0 then
      fill(0, 0) -- clear all chars on the page
      clear()
      display()

      read_index = load_index(page - 1)
      load_page(page - 1, active_print_fn)
   end

   if btnp(5) then

      fill(0, 0) -- clear all chars on the page
      clear()
      display()

      load_page(page + 1, active_print_fn)
   end

   display()
end
