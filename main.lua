txtr(0, "overlay.bmp")


local pg_color = 0xf0eddf
local text_color = 0x2f264e


fade(1, pg_color, true, false)


book_data, book_len = file("book.txt")


local page = 0
local read_index = 0


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
   while true do
      local chr = read_char()
      if chr ~= "\r" then -- skip carriage-return
         if is_delimiter(chr) then
            return word, chr
         end
         word = word .. chr
      end
   end
end


local carry_word = nil
local carry_delim = nil

local x_write = 1
local y_write = 2


function handle_delimiter(delim)
   if delim == "\n" then
      y_write = y_write + 2
      x_write = 1
   elseif delim == " " then
      print(delim, x_write, y_write, text_color, pg_color)
      x_write = x_write + 1
   end
end


function load_page(pg)

   page = pg

   fill(0, 0) -- clear all chars on the page
   clear()
   display()

   local page_num = tostring(pg + 1)
   print(page_num,  (29 - string.len(page_num)), 18, text_color, pg_color)


   x_write = 1
   y_write = 1

   if carry_word then
      print(carry_word, x_write, y_write, text_color, pg_color)
      x_write = x_write + utf8.len(carry_word)
      handle_delimiter(carry_delim)
      carry_word = nil
      carry_delim = nil
   end

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
            carry_word = word
            carry_delim = delim
            return
         end
      end

      print(word, x_write, y_write, text_color, pg_color)
      x_write = x_write + word_len

      handle_delimiter(delim)
   end
end


load_page(0)


print(tostring(collectgarbage("count") * 1024), 0, 19, text_color, pg_color)
print("hello.", 0, 18, text_color, pg_color)


while true do
   clear()

   if btnp(4) then
      load_page(page - 1)
   end

   if btnp(5) then
      load_page(page + 1)
   end

   display()
end
