txtr(0, "overlay.bmp")


local pg_color = 0xf0eddf
local text_color = 0x2f264e


fade(1, pg_color, true, false)


book_data, book_len = file("book.txt")


-- To make backtracking into a Unicode string easier, I'm storing a table of
-- indices into the book data in SRAM. When we need to go back a page, we can
-- simply reset our position to a previously visited index.
local index_array = _SRAM + 12


local index_frequency = 8


-- Store a magic number in the first index of SRAM. That way, we'll know if
-- we've written any safe data before, or whether SRAM contains uninitialized
-- junk.
if peek4(_SRAM) == 0xaaaa then
   read_index = peek4(_SRAM + 4)
   page = peek4(_SRAM + 8)
else
   read_index = 0
   page = 0
   poke4(_SRAM, 0xaaaa)
end



local recent_pg_count = 8
-- Keep a cache of recent pages, helps us flip between pages more quickly
local recent_pages = {}
for i = 0, recent_pg_count do
   recent_pages[i] = {
      pg = 0,
      index = 0
   }
end

local recent_pg_write_index = 0


-- Store the location of a recent page in our page cache
function store_recent_page()
   for k, v in pairs(recent_pages) do
      if v.pg == page then
         return
      end
   end
   local info = recent_pages[recent_pg_write_index]
   info.pg = page
   info.index = read_index
   recent_pg_write_index = (recent_pg_write_index + 1) % recent_pg_count
end


-- Store location of a visited page in SRAM
function store_index()

   poke4(_SRAM + 4, read_index)
   poke4(_SRAM + 8, page)

   -- Every so often, we write the byte offset of a visited page to SRAM. This
   -- helps us to quickly jump to previously-visited pages, and we don't have to
   -- parse everything all over again if we turn off the gba.
   if page % index_frequency == 0 then
      local slot = math.floor(page / index_frequency)
      poke4(index_array + slot * 4, read_index)
   end
end


function get_nearest_cached_page()
   if page % index_frequency == 0 then
      local nearest = page - index_frequency
      local slot = math.floor(page / index_frequency) - 1
      local index = peek4(index_array + slot * 4)
      return nearest, index
   else
      local nearest = page - page % index_frequency
      local slot = math.floor(page / index_frequency)
      local index = peek4(index_array + slot * 4)
      return nearest, index
   end
end


function get_nearest_prev_page()
   local nearest, index = get_nearest_cached_page()

   for k, v in pairs(recent_pages) do
      local pg = v.pg
      if pg < page and page - pg < page - nearest then
         nearest = pg
         index = v.index
      end
   end

   return nearest, index
end


-- NOTE: all of the read_* functions are stateful.
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
   while read_index < book_len do
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


function backtrack(word, delim)
   read_index = read_index - (string.len(word) + string.len(delim))
end


function read_page(print_fn)

   x_write = 1
   y_write = 1

   while read_index < book_len do
      word, delim = read_word()

      if y_write >= 17 then
         backtrack(word, delim)
         return
      end

      local word_len = utf8.len(word)
      if word_len + x_write > 28 then
         x_write = 1
         y_write = y_write + 2

         if y_write >= 17 then
            -- We ran out of room, subtract the read-offset by the length of the
            -- last processed word.
            backtrack(word, delim)
            return
         end
      end

      print_fn(word, x_write, y_write)
      x_write = x_write + word_len

      if delim == "\n" or delim == "\r\n" then
         y_write = y_write + 2
         x_write = 1
      elseif delim == " " then
         print_fn(delim, x_write, y_write)
         x_write = x_write + 1
      end
   end
end


function active_print_fn(str, x, y)
   print(str, x, y, text_color, pg_color)
end


function void_print_fn(str, x, y)
   -- Do nothing...
end


function on_page_transition()
   local page_num = tostring(page + 1)
   active_print_fn(page_num, (29 - string.len(page_num)), 18)
end


function before_page_transition()
   store_recent_page()
   store_index()
end


before_page_transition()
read_page(active_print_fn)
on_page_transition()


-- print(tostring(collectgarbage("count") * 1024), 0, 19, text_color, pg_color)


function clear_page()
   fill(0, 0)
   clear()
   display()
end


while true do
   clear()

   if btnp(4) and page > 0 then

      clear_page()

      -- Seek the nearest page that we have data cached for. Then scan through
      -- each page until we reach the desired one.
      prev_page, index = get_nearest_prev_page()
      read_index = index

      while prev_page < page - 1 do
         read_page(void_print_fn)
         prev_page = prev_page + 1
      end

      page = page - 1

      before_page_transition()
      read_page(active_print_fn)
      on_page_transition()

   end

   if btnp(5) and read_index < book_len then

      clear_page()

      page = page + 1

      before_page_transition()
      read_page(active_print_fn)
      on_page_transition()

   end

   display()
end
