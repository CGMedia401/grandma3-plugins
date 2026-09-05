local pluginName     = select(1,...);
local componentName  = select(2,...);
local signalTable    = select(3,...);
local my_handle      = select(4,...);

--[[
=====================================================================
 PixelGroupStore.lua  -  GrandMA3 Plugin
=====================================================================
 WHAT THIS DOES
 Asks which fixture type you're working with (PIXEL LINE IP / JDC 68 CH /
 STRIKE M 97 CH), then a fixture number (or range), then selects that
 fixture's RGB pixels and White pixels in turn - arranging each into the
 Selection Grid via the same command sequence used by hand on the console -
 and stores each selection into whichever of the three PIXEL groups you
 pick, color-coded to match GroupCleanupV4's PIX1/PIX2/PIX3 swatch colors.

 STRIKE M 97 CH and JDC 68 CH are implemented. PIXEL LINE IP is a
 placeholder until its addressing is provided - picking it just shows a
 "not set up yet" message.

 PER-TYPE PIXEL ADDRESSING (user-confirmed, 2026-09-01) - see
 FIXTURE_PROFILES below for the full detail:
   STRIKE M 97 CH: nested fixtureNum.part.pixel, part 1 = RGB, part 2 = White
   JDC 68 CH:      flat fixtureNum.pixel, no part number

 -------------------------------------------------------------------
 SAFETY
 -------------------------------------------------------------------
 - The target groups (PIX1/2/3 RGB/White Pixels) already exist and are
   always overwritten (Store ... /o /nc), matching how this is done by
   hand - there is no "already exists" confirmation, so double-check
   the fixture number and chosen group before clicking.
 - Not yet live-tested - check System Monitor on first run to confirm
   the Fixture/Down/Grid sequence does what's expected before trusting
   the Store step.
=====================================================================
]]--

-- ===================================================================
-- Self-installing CG Media & Lites logo + PIX1/2/3 color swatches
-- ===================================================================
-- Same proven pipeline as GroupCleanupV4/SaveShowAs2/SaveShowAs3: raw file
-- bytes embedded as base64 below, written out under
-- GetPath(Enums.PathType.Textures) the first time this plugin runs on a
-- given console/onPC, then registered as a Texture object. Copying just
-- this one .lua file anywhere is enough - no separate manual texture copy
-- needed per machine. Own texture namespace (PixelGroupStore/...) so this
-- plugin never depends on GroupCleanupV4/SaveShowAs2/3 being present.
--
-- Swatch colors reused verbatim from GroupCleanupV4's settled PIX1/PIX2/PIX3
-- swatch images (same RGB, just re-embedded under this plugin's own file
-- names) so the color coding matches across both plugins:
--   PIX1 = (169,51,255) purple   PIX2 = (255,153,51) orange   PIX3 = (51,255,153) teal

local LOGO_TEXTURE_NAME = 'PixelGroupStore_Logo'
local LOGO_TEXTURE_FILE = 'PixelGroupStore/cg_logo.tga'

local SWATCH_FILES = {
    [1] = 'PixelGroupStore/swatch_pix1.tga',
    [2] = 'PixelGroupStore/swatch_pix2.tga',
    [3] = 'PixelGroupStore/swatch_pix3.tga',
}

local EMBEDDED_TEXTURES = {
    ['PixelGroupStore/cg_logo.tga'] = (

        'AAAKAAAAAAAAAAAARwBAACAoBVVVqgOmp6mhYmJi8RwcHFAAAAABMzMzBbAAAAAABj8/PwQAAAACHh4eU2lqat+lp6pyAAAAAP///wKIAAAAAA' ..
        'OqqqoMioqL8DU1Nf8gICC7gQAAAAABVVVVAwAAAAGsAAAAAAEAAAABVVVVA4EAAAAABSAgIMdHR0f/kZGS6wAAABMBAQEAAAAAAYcAAAAABQAA' ..
        'AABBRERdIyMjtCEhIWo7PT1nR0dHMoEAAAAAAVVVVQMAAAABqAAAAAABAAAAAVVVVQOBAAAAAAdKSkopRUVIVCUlKGUmJibPOzs7hAAAAA4AAA' ..
        'AAAAAAAYcAAAAAgQAAAAAFAAAAAQAAAAAxMTEaPT09dUVFRoVbW1sqgQAAAAABPz8/BAAAAAGkAAAAAAEAAAABVVVVA4EAAAAAB1paWiJISEp4' ..
        'PkBAcyYmJigAAAAAAAAABgAAAAsAAAABiQAAAAADAAAAAFVVVQMAAAAAAAAAAYEAAAAAAzMzMzxBQUGkS0tNjW5ubh6BAAAAAAA/Pz8EogAAAA' ..
        'AAVVVVA4EAAAAACHJychRQUFB/Q0NEoy0tME8AAAAIAAAAAAAAAAIAAAAAAQEBAIoAAAAAgQAAAAADAAAAAQAAAAAAAAABVVVVA4EAAAAAAzY2' ..
        'NmdFRUXFU1VVhIiImQ+BAAAAAABVVVUDngAAAAAAVVVVA4EAAAAABr+/vwhZWVt1RkhIwjAwM30AAAAZAAAAAP///wGBAAAAAIEAAAABigAAAA' ..
        'CFAAAAAAoAAAAC////AQAAAAAAAAASOTk5k0tLS9VfX19z////AwAAAAAAAAABVVVVA5oAAAAAgX9/fwIHAAAAAAICAgBgYGNkTU1Nzjc3N6kF' ..
        'BQUzAAAAAP///wGQAAAAAIcAAAAAAFVVVQOBAAAAAAMeHh4yPj8/vVFRUdloaGhdgQAAAACBf39/AocAAAAAAgAAAAFVVVUDf39/BII/Pz8EAX' ..
        '9/fwIAAAABhgAAAAABf39/AlVVVQOBAAAAAAZqampPVFRUzTw8Ps0XFxdWAAAACAAAAAD///8BkQAAAACIAAAAAAEAAAABPz8/BIEAAAAAAycn' ..
        'J1pCQkPeV1dXz3BwcEaBAAAAAAFVVVUDf39/AoMAAAAAAgAAAAGqqqoDAgEBAIYAAAAAAFVVVQODAAAAAAEAAAABVVVVA4EAAAAACHB0dDtZWV' ..
        'vBQ0ND5SMjJXsAAAAWAAAAAP///wEAAAAAAAAAAZEAAAAAigAAAAAHAAAAAn9/fwIAAAAAAAAABy8vL4VHR0fzXFxcu3d8fDGBAAAAAA4/Pz8E' ..
        'AAAAAQAAAABVVVUDAQEBAAAAAAAAAAAMW1tbPX5+fm1MTE6CPj4+f0FBQWVCQkgu////AQAAAACBAAAAAQEAAAAAqqqqA4EAAAAACHl5fyhhYW' ..
        'GtSUlJ9CwsLKEAAAArAAAAAQEBAQAAAAAAAAAAAZMAAAAAjAAAAAAHVVVVAwEBAQAAAAAAAAAAITMzM61MTEz7ZWVloYiIiB6BAAAAAA1mZmYF' ..
        'AAAAAAAAABZydHSGpaam4ri4uf9zc3P/RERE/0BAQP8+Pj7/OTk5/y8vL841NzdgAQEBAIIAAAAAB5aWlhZoaGiTT09P+DQ0NMMDAwNFAAAABg' ..
        'EBAQD///8BlgAAAACNAAAAAAEAAAABPz8/BIEAAAAAGxMTE0E4ODjQUVJS+mxsboS2trYOAAAAADs7O0CXmZrh2tvb/8/P0P9aWlr+MTEx+zo6' ..
        'Ovs3Nzf7NTU1+zQ0NP8vLy//Hh4e/yoqKqdmZmYF////BW1tb3dVVVXwOTk63hISEmMAAAAQAAAAAP///wGBAAAAAZYAAAAAjwAAAAABAAAAAl' ..
        'VVVQOBAAAAABkcHBxjPT097FhZWOpLS0uAnJyd9ODg4f/Hx8j6ZmZn/jIyMv8+Pj7/ODg4/zU2Nv80NDT/MTEy/zEyMv0nKCj7EhIT/zM1NsBd' ..
        'Xl/TQEFB+hweIIcAAAAhAAAzBT9/fwQAVVUDAABVA4EAAAACggAAAAGFAAAAAIIAAAABBAAAAAIAAH8CAFVVAwBVqgM/f38Egj9/vwQCVaqqA3' ..
        '9//wIAAAAAkQAAAAAVVVVVA3///wIAAAAAAAAADhkaHI56e3z/2drb/76/wf2YmZr/OTo6/zs7O/82NTX/MjIx/y4tLP8qKSf/KCYk/yYjIP8p' ..
        'JiP/ExAN+hIPC/8nIh7DAAAAGYQAAAAABQEAAAACAAAAAwEAAAQDAQAFAwIABgUDAIEGBgUAgQcGBgAGBwYFAAYGBQAGBQQABQMCAAQCAAADAA' ..
        'AAAQAAAIgAAAAAiQAAAAACAAD/Af///wF/f/8CgT9/fwQCPz9/BABVVQMAAAACgwAAAAAwSD0zRsXDwfvT0M77vbq3/25saf85ODb/QD8+/zw9' ..
        'Pv88PkD/QURI/0NKUP9ASVP/P0tX/z5MWv89TV39MEJT/EZfds5mlsZwX428fl6Mt4xkjbWdZIqxqF+GrbBZgai3UnukvFB4ocJLdZ7HSnWfyU' ..
        'p0n81Kc57RSXOd0Uh0n9JJdZ/TSnWf0Ux3odFOeKLPT3qlylJ9qcdYhK7BXoq2ummUwLNsmMSpbZrHmGiYx4Func9xc6PWX3au40l6qtkwttr/' ..
        'B4MAAAAABQAAAAF/f38CVaqqAz9/fwQAP38EAAAAAoYAAAAADAQDAwD///8Ipuj/F4K68ilyp+A6ZnmLw6e5y/+JoLf8co2n/05rhv9BX3z/QW' ..
        'B+/zxbev+BOFVy/xI3VXL/ME5r/ytJZv8oRWH/J0Nd/ydBW/8lPlb/JT1U/yQ6T/8hN0z/IDNG/x0wQf8bLD3/Gio5/xooNv8ZJjL/FyQv/xcj' ..
        'L/8WIy7/gRYiLv8RFiIt/xYjLv8VIi3/FSMx/xYlM/8XJzb/GCk6/xksPv8bMUX/HTVL/yA6Uv8jP1r/J0Vi/yxNbf8xVXj/M1h9/0V1pP9Ec6' ..
        'BWA39/fwJVqqoDPz9/BAAAAAKEAAAAAB0DAgIA////BpTU/xhzquEzXY3AWk1+r3dIdaWRQGqUqjpfhMM6XH3gMFNz8i1Maf0tSmb/J0Fb/xcu' ..
        'Q/8TJjj/ESIx/xUjMP8XIy3/Fh8o/xYdJP8VGyD/FRkc/xUXGf8XFxb/GBcW/xcWFP8XFRT/GRYU/xsYFv6BGxgW+wMcGRb7HBoY+x4bGfsfHB' ..
        'r8gh8dG/yBIB4c/AAhHx39gSIgHv0RIyEf/SEfHv0pJyX9KCYl/SclJP0nJSP8JiQj/CUjIfwjIR/8IR8c/B0cGvsbGRf7GBcV+xUUFPsUFRb7' ..
        'GB4j/Eh5qv8rT3NdgwAAAAAV////BGes6iVRi8VLSnqtbkBslpI7YorCM1h83y5PcfMqRmH/JT1V/yI3S/8hMkP/Hyw4/xokLP8WGyD/EhUW/x' ..
        'ETEf8SExD+FBUR/hgaFf8bHBb/Hx8a/4EfHxv/DCAgHP8hIR3/ISEe/yAgHf8gIB7/Hh8d/xweHP8cHBv/HRoa/x4bG/8fGxz/Hhsc/x4cHP+B' ..
        'Hh0d/xAeHh7/HR0e/xwdHf8dHR3/Hh8f/x8fH/8fICD/IiIi/yIjI/8jIyT/ICAh/zY3N/9YWVn/R0hI/0dHSP9GRkb/R0dH/4FISEj/AElJSf' ..
        '+BRUVF/wVDQ0P/RUVG/yclI/8jKjL/UIa6+yNAXUcuUIrEI0+Hw01BcKCEOWSQtzFWe9ooR2P6JkFb/yM5Tf8eLTv/GSIq/xYbH/8XGRr/FhYW' ..
        '/xQSEPwRDgz7DAoJ+wsJCvsQDxH8GRoY/SQiJP4lICb+JB0m/yUcKP8qHiz/Myc1/zImNP8sIy//Ihok/xwUHv8bExz/GREb/xYOGP8VDRb/Eg' ..
        'oU/xIJEv8NDBL/BBES/wIQEf8DEhP/AAgJ/wAHCP8FDQ7/DxQU/xgZGf8gHh7/IiAg/yEgIP+BHx8f/4IiIiL/CCMjI/8hISH/OTk5/zo6Ov8a' ..
        'Ghr/IyMj/yIiIv8eHx//JSUl/4EiIiL/BygoKP8jIyP/Kisr/y8wMP8dGhj+JjI+/1GFu/IWKD84G0BsmOgmQV3/HzBA/xokLv8YHSH/ExMT/x' ..
        'EPDPwPDQr7DgwK+w4MC/wJCQj9BQUF/gECBP8ICQ3/FBYX/x0eG/8wMCX/Li4f/yYfJf8vNi//KD0l/yBCG/8hUxr/J3Md/yuHHv8vmh//M64i' ..
        '/zW0Iv+ENLQi/w43syP/LbUk/2V8Hv+mFRT/kR0T/4IZEf9wFQ//VA8K/zIJBv8XBAL/AwEB/wADBP8ACgv/FRcX/yEfH/+DIiIi/xIkJCT/Iy' ..
        'Mj/z09Pf86Ojn/Gxsb/yUlJf8mJib/Hx8f/yUlJf8jIyP/Hx8f/yUlJf8fHx//ICAg/ycoKP8cGBX+LkBS/1KHvukGDBIpGUBmjPUUFhn8DAkG' ..
        '+wcFBPwEAwL9AwIC/gMEBP8DAwT/AwMD/wAAAP8DBAf/FRUX/yorJP8tLB//LCwm/xsbKf8YGVL/FBp4/zCgMf9A3SX/RvEu/0v+Mv9P/zX/Uv' ..
        '83/1P/OP9U/zn/hlP/Of8EVv85/0b/Ov+buzH//ycl//85Jv+B/zYm/x7/NSX//zQk//IwIv/ZKx7/nR8V/0kNCf8HAAD/AAQF/xsaGf8kJCT/' ..
        'ISEh/yMjI/8lJSX/JCQk/z4+Pv82Njb/Hh4e/yYmJv8qKir/ICAg/yQkJP8lJSX/IiIi/yUlJf8mJib/ISEh/ywtLv8ZFBD9PFZw/1eLv9QAAA' ..
        'AZAUNoj/cVGR7/ggAAAP8SAwMD/wYGBv8AAAD/AwQH/x8gHP8wMCP/JSQd/xkaOf8RFHH/Fhu9/x0j5f8iKP//JzP//07zVP9T/zH/UP84/07/' ..
        'Nf9O/TX/Tfs0/4FM+TT/gU37NP8BTfo0/037NP+CTfw0/wRQ+TT/Qfw1/5CuLf/7IyL/+DQi/4H7MSL/CfwxI//+MiP//zMj//80JP//Nib//z' ..
        'Ql/94uIP9nEw3/AAAA/xsZGf+BJCQk/xIlJSX/JiYm/z4/P/81NTX/ISEh/yQkJP8pKSn/IyMj/yUlJf8mJib/KSkp/ycnJ/8mJib/ISEh/y8w' ..
        'MP8WEg38Q2KB/1GEuMAAAAALG0JnjfsUGBz/AgEA/wAAAP8DAwP/BQUF/wAAAP8XFxn/NDQm/yUlNf8UF2r/Fhux/x8m8v8mLv//Jy7//yUu//' ..
        '8kKf3/JC/2/0jiTf9P/S//Tv02/07/Nf9N/jX/T/82/1H/N/9Q/zb/T/81/0//Nv+BUP82/wBO/jX/gU7/Nf8EUfw1/0L/Nv+SsC7//yQi//w1' ..
        'I/+D/zIj/xD+MiP//TIj//sxIv/8MSP//zQk//80Jf8mBwX/AwQF/yYkJP8kJCT/Jycn/yYmJv9AQED/MzMz/yUlJf8kJCT/KCgo/4ElJSX/AC' ..
        'cnJ/+BJiYm/wYoKCj/ISEh/zEyMv8WEg78SW2R/0t+sLAAAAACJUJni/wVGBz/AQAA/wICA/8FBQb/AAAB/ykpKf84Ny7/EhRh/xsh3f8mLf//' ..
        'Jy7//yUs//8jKvz/JCv8/yQs/f8kKf//JTD6/0nlTv9P/y//Tv42/07/Nf9Q/zb/Suwz/0DKLf89vSv/OrMp/z28K/9Axy3/R+Mx/1D/Nv9P/z' ..
        'X/Tv41/1H8Nf9C/zb/krAu//8kIv/8NSP/h/8yI/8F+TAi//82Jv95GBH/AAAA/x8bG/8mJyf/gScnJ/8QQUFB/zExMf8sLCz/JCQk/ykpKf8m' ..
        'Jib/KCgo/ysrK/8lJSX/JiYm/yoqKv8jIyP/MTIy/xoWE/xOd5//SXmqnQAAAAAJQmeM+hUZHv8DAgH/BQUG/wEBAf8aGhz/Ozs0/wwRkf8lLf' ..
        '//Ji3//4EkKvz/ACQr/v+BJCv//xYkLP7/JCn//yUw+v9J5U7/T/8v/079Nv9P/DX/QMct/z27K/9G2zD/S/Az/033NP9M9TT/SOMy/z28Kv87' ..
        'tSn/TfQ0/0//Nv9R+zX/Qv82/5KwLv//JCL//DUj/4f/MiP/BfwxI//+NSX/tyUa/wAAAP8RDw7/Jycn/4EoKCj/B0NDQ/8vLy//MDAv/yUlJf' ..
        '8qKir/Jycn/yoqKv8vLy7/gSYmJv8GKCgo/ywsLP8xMTH/FxUT/FJ+q/9EcqCKAAAAAAlCZoz4Fxsg/wUEA/8FBQX/AQED/zg4Lf8PEUn/JCz/' ..
        '/yQr+/8kK/3/hCQr//8HJCz+/yQp//8lMPr/SeVO/0//L/9O+zf/Qs8u/0fgMf+BUP82/wBP/zX/gU7/Nf8JT/82/1H/N/9J5zL/ObEo/0zyNP' ..
        '9S/TX/Qv82/5KwLv//JCL//DUj/4f/MiP/GP4yI///MyP/8TAh/xIDAv8CBQX/JyYm/yoqKv8nJyf/Q0NE/y0tLf8uLi7/JiYm/ysrK/8uLi7/' ..
        'Jycn/ywsLP8oKCj/LCws/y0tLf8pKSn/Li4t/xgZGfxaibj/QGmTdwAAAAAIQWeN9xccIv8GBQP/AQEB/xISFf8rKyD/Ehen/ygv/v8jKvv/hS' ..
        'Qr//8JJCz+/yQp//8lMPr/SeRN/1D/MP9G3DL/Suwz/1H/Nv9O/TX/Tv41/4JO/zX/CU7+Nf9N/DX/Uf83/0nqMv85sCj/Uv02/0L/Nv+SsC7/' ..
        '/yQi//w1I/+I/zIj/wf9MiP//zQk/z0MCP8AAAD/JiMj/ywsLP8mJib/Q0ND/4ErKyv/DScnJ/8tLS3/NDQ0/yYmJv8qKir/KSkp/y4uLv8vLy' ..
        '//KSoq/yooJv8fJSv9ZJbG/zdafGAAAAAACEFnj/YYHiT/BwYF/wAAAP8mJiD/ICA4/x0k8/8lLP//JCv+/4UkK///ByQs/v8kKf//JTD6/0nn' ..
        'Tv9O/S//S+k1/0//Nf9O/TX/hk7/Nf8HTf01/1H/N/9Bzy3/R9cv/0T/OP+Rry7//yQi//w1I/+I/zIj/xf7MSL//zYm/3EXEP8AAAD/IR0d/y' ..
        '4uLv8mJib/Q0ND/yoqKv8sLCz/KCgo/ywsLP8xMTH/KCgo/ysrK/8rKyr/KSkp/yoqKv8uLy//JiMh/iYvOf9bjsD+IjxXQwAAAAAHQ2iP8xkf' ..
        'Jv8IBgX/AQEE/yUkGP8TFFH/JCv//yQr/f+GJCv//wUkLP7/JCn//yUv+v9J6E7/TfYv/035N/+BTv81/wBO/jX/gk7/Nf+CTv41/wdO/zX/Tv' ..
        '41/036NP9Dxi3/Q/83/5KvLv//JCL//DUj/4j/MiP/F/sxIv//NSX/mh8W/wAAAP8bGBj/Ly8v/yUlJf9CQkL/KSop/y0tLf8qKir/KSkp/y0t' ..
        'Lf8oKCj/LS0t/zMzM/8oKCj/KSoq/zEyMv8hHhv+KzpI/1qOwfcPJDQxAAAAAAdDapHuGiEp/wkIBv4GBwv/Kika/xQXiP8mLv//Iyr7/4YkK/' ..
        '//BSQs/v8kKf//JTD6/0nmTv9N8i//Tv02/4FO/zX/AE//Nv+CTv81/4JP/zX/B07/Nf9O/jX/T/82/0C+K/9A/zX/krIu//8kIv/8NSP/iP8y' ..
        'I/8X/DEj//81Jf+8JRr/AAAA/xUTE/8vLy//JSUl/0RERP8qKir/LS0t/y8vL/8pKSn/LS0t/ykpKf8sLCz/NDQ0/ygoKP8uLi7/OTk6/xwYFP' ..
        '4zRln/W4/C6wAAByIAAAAAB0ZuluobIyz/CgkH/g0OEf8wLyL/Exij/ycv//8jKvv/hiQr//8FJCz+/yQp//8lMPr/SeVN/0fjK/9O/jf/gU7/' ..
        'Nf8GSOMy/0nkM/9K4TT/TO81/0rmNP9L5TX/Sucz/4FO/jX/BVD/Nv88sij/P/80/5OzL///JCL//DUj/4j/MiP/F/0yI///NCT/4S0g/wcBAP' ..
        '8LDQ3/MC8v/yYmJv9DQ0P/Kioq/y0tLf82Njb/Kioq/y0tLf8wMDD/Kioq/y4uLv8qKir/LS0t/zk6Ov8XEg/9OlNs/1qNwN0AAAAWAQEBAAdK' ..
        'cJnkHCUw/woJB/4QEhT/IiEZ/xUbuf8nLv//JCv8/4YkK///FiQs/v8kKf//JTD6/0nnTv9H3yv/Tfw2/07/Nf9P/zX/Rtsx/0z3NP9P+jf/Tv' ..
        '41/071Nv9M8zX/R98y/07/Nf9O/jX/T/82/zefJP9A/zX/krIu//8kIv/8NSP/iP8yI/8X/jIj//8yI//6MSP/HAQC/wIICP8wLy//Jygo/z8/' ..
        'P/8nJyf/LCws/zU2Nv8qKir/Li4u/zg4OP8qKSn/LS0t/ywsLP8pKSn/MzQ1/xQQDPxJaov/XIy9ygAAAAsBAgIAB1B2nt0dKDT/CwkH/hMUFf' ..
        '8aGhn/GR/P/yYu//8kK/3/hiQr//8WJCz+/yQp//8lL/r/SutO/0bfKv9L8TX/Tv81/0//Nf9L9DT/R+Ex/1D+N/9O+zb/UP83/0npM/9L8DP/' ..
        'T/81/0//Nv9K8jP/N58k/0T/OP+Rry7//yQi//w1I/+I/zIj/wf+MiP//zIj//4yI/8nBgT/AAUG/zEvL/8pKSn/PDw8/4EuLi7/DTAwMP8pKS' ..
        'n/LS0t/zIzMv8oKCj/LS0t/zU1Nf8oKCj/MjMz/xANCvxYfaH/XYizrAAAAAICAwMAB1d9o9cdKTf/CwkH/RYXFP8ZGSL/HCLh/yYt//8kK/7/' ..
        'hiQr//8WJCz+/yQp//8lL/r/SupO/0rwLP9F2TH/UP82/039Nf9O/zX/R94x/0jmMv8qex//P8Us/0nnM/9N+zT/Tf01/1L/N/8+xyv/QMAq/0' ..
        'X/Of+Rri7//yQi//w1I/+J/zIj/wj+MiP//zQk/zQJBv8ABAX/MjAw/ysrK/83Nzf/NTU1/zMzM/+BNDQ0/wszMzP/NTU1/zQ0NP81NTX/OTk5' ..
        '/zY2Nv8sLS3/ExEP/FmDrf9NeaaVAAAAAP///wEHWYCmzR8uPf8KCQf9GxwY/xkaLf8dJO3/JSz//yQr/v+GJCv//xYkLP7/JCn//yUw+v9J5E' ..
        '3/UP8w/z/FLv9M9zT/Tv41/0//Nv9K7TP/SOQy/0DBLv9G2jH/Segy/0//Nv9O/TX/T/01/zanJv9P9TT/Qv82/5KwLv//JCL//DUj/4n/MiP/' ..
        'Dv0yI///NCX/QQwI/wACA/8zMDD/KSkp/xoaGv8bGhr/Hh0d/yAfH/8jIyP/Jycn/ygoKP8oJyf/JiYm/4EiIiL/BRkYGP8YGBj8XIq3/0ZwmH' ..
        '8AAAAAf///AgdXgKm7JDZJ/woIB/0iIx3/Ghs3/x8m9/8lLP//JCv+/4YkK///FiQs/v8kKf//JTD6/0nkTf9R/zD/RuEy/0HNLf9Q/zb/Tf01' ..
        '/07+Nf9E1DD/L4kj/z21LP9N+jX/Tv41/1H/N/9B0C3/P8ks/1T/N/9B/zb/krAu//8kIv/8NSP/if8yI/8H/DEj//81Jf9QDwr/AAIC/zIvL/' ..
        '8qKir/JCQk/yUlJf+BJCQk/wQlJSX/JiYm/yUlJf8jIyP/IiIi/4EhISH/BSQjIv8eISP8Xo69/z5iiWoAAAAAf///AgZVgKynJzxS/w0KCfwm' ..
        'Jx//Ghs+/x8m+/8lLP//hyQr//8WJCz+/yQp//8lMPr/SeVO/0//L/9Q/zj/P8Qs/0vzM/9P/jX/Tv01/zSfJf88sSr/MZcj/0jpMv9P/jb/Tv' ..
        'o1/zivKP9O/DX/Ufw1/0L/Nv+SsC7//yQi//w1I/+J/zIj/wn8MSP//zUl/1UQC/8AAgP/MzAw/yoqKv8jIyP/JCQk/yUlJf8kJCT/gSAgIP8B' ..
        'IiIi/yQkJP+BJSUl/wYlJSb/JCIg/yMqMf5klMT/MlNzVgAAAAB/f/8CBlqItJspQFj/DgwK/CYnH/8ZG0L/ICf//yUs//+HJCv//xYkLP7/JC' ..
        'n//yUw+v9J5U7/T/8v/0//N/9I6TL/QMct/1D/Nv9P/jb/Mpck/yl6Hv8uiSL/Se0y/1L/N/9C0y7/Qc4t/1H/N/9Q+jT/Qv82/5KwLv//JCL/' ..
        '/DUj/4n/MiP/FvwxI///NSX/TA4K/wACA/81MzL/Kioq/yMjI/8lJSX/IiIi/yEhIf8zMzP/ODg4/ysrK/8hISH/IyMj/yQkJP8kJSb/IR4b/i' ..
        '48Sv9unMr6HDVKPgAAAAB/f38CBluKuo4rRF7/Dw0M/CYmHv8YGkL/ICj//yUs//+HJCv//xYkLP7/JCn//yUw+v9J5U7/T/8v/039Nv9P/zb/' ..
        'O7kq/0v1M/9R/zf/Losg/yBfF/8sgx//R+Yx/1H+N/85tCj/S/Mz/0//Nf9R/DX/Qv82/5KwLv//JCL//DUj/4n/MiP/Fv0yI///NSX/RAwI/w' ..
        'ADBP84NjX/Kioq/yMjI/8iIiL/KCgo/2VlZf+UlZX/hISD/3V1df87Ozv/Ghoa/yMjI/8lJif/HxwY/jZJXP9jlMbpAAAHJAAAAAAAAAABBl+P' ..
        'vYAtSGT/Dw0N/CUmHv8ZGkL/ICf//yUs//+HJCv//xYkLP7/JCn//yUw+v9J5U7/T/8v/038Nv9Q/zb/P8Ys/0rvM/9P/jX/NaEm/zyzK/88tC' ..
        'v/SOYy/1H/N/87tir/Tf01/07/Nf9R/DX/Qv82/5KwLv//JCL//DUj/4n/MiP/Fv0yI///NCX/PAsH/wAFBv85Nzf/KCgo/yMkJP8gICD/ZGRl' ..
        '/7e3uP+goKD/k5OT/5qbm/8hISH/Dw4O/x0dHf8lJif/HRoW/T1Vbf9fkcLaAAAAFQEBAQAAAAABBmSTxHIuS2n/EA4O/CMjG/8ZG0L/ICf+/y' ..
        'Us//+HJCv//xYkLP7/JCn//yUw+v9J5U7/T/8v/038Nv9R/zf/QtIt/z7EK/9U/zn/M5sl/zuuK/81pCb/RuQw/0rvM/83rSf/UP82/039Nf9R' ..
        '/DX/Qv82/5KwLv//JCL//DUj/4n/MiP/Fv4yI///NCT/MwkF/wEKCv84Njb/Jycn/yAgIP8yMjL/lpaW/6mpqf+NjY7/qqus/zg4OP8CAwP/FB' ..
        'QU/xESEv8jJCX/HBgU/ENhfv9ejr/IAAAACwECAgAAAAABB2may2MvTm7/ExIS/R4eF/8XGDn/ICf7/yUs//8kK/7/hiQr//8WJCz+/yQp//8l' ..
        'MPr/SeVO/0//L/9O/jb/Tfw0/1L9OP8mdhv/FT0Q/w8tC/8NJgr/H1gX/yFdGP8YSRH/Sugy/0/+Nv9O/jX/Ufw1/0L/Nv+SsC7//yQi//w1I/' ..
        '+K/zIj/xX/MyT/LAcE/wUNDv83NTX/JiYm/yAgIP85OTn/kZKR/4qLiv+sq6r/W1tb/wABAf8UFBT/ERER/wsMDP8hISL/HBgV/E5ylv9biLez' ..
        'AAAAAgICAwAAAAABB3Si01MyUnT/FhYW/RkaFf8UFSr/Hybw/yUs//8kK/7/hiQr//8IJCz+/yQp//8lMPr/SeVO/0//L/9O/jb/Tfs0/1T/Of' ..
        '8tjh//ggAAAP8KJ28c/x5UFv8RNQz/VP85/039NP9O/zX/Ufw1/0L/Nv+SsC7//yQi//w1I/+I/zIj/xf+MiP//zIj//8yJP8mBQP/CRAR/zc1' ..
        'Nf8kJCT/ISEh/zExMf9ubm7/m5qY/4KFkP8FBwr/EBAP/xYVFf8LDAz/CwsL/yIiIv8cGxr8YImy/1uCqpQAAAAA////AQAAAAEHkLrkQzhafP' ..
        '8XGBr+GhoX/xMUG/8cI+D/Ji3//yQr/f+GJCv//xYkLP7/JCn//yUw+v9J5U7/T/8v/07+Nv9N/DT/U/84/zSkJf8BAwH/AgUB/wECAP8UNRD/' ..
        'CRMH/xlQEv9S/jj/Tfw0/07/Nf9R/DX/Qv82/5KwLv//JCL//DUj/4j/MiP/F/4yI///MyP/8TAi/xICAf8RFRb/NjU1/yMjI/8kJCT/Hx8g/0' ..
        '5NSf+coK3/GShQ/wkJBv8WFhb/Dg8P/wYHB/8RERH/JSUk/xweH/xok73/T3SXdgAAAAD///8BAAAAAAecxe0sOFt/+hgcIf8XFxb+ExMU/xsh' ..
        '1f8mLf//JCv9/4YkK///FiQs/v8kKf//JTD6/0nlTv9P/y//Tv42/038NP9T/zj/NKQk/wECAP8BBAH/AAAA/xc9Ev8KGQj/GlIS/1P/OP9N/D' ..
        'T/Tv81/1H8Nf9C/zb/krAu//8kIv/8NSP/iP8yI/8X/TIj//80Jf/QKR3/AAAA/xsbG/80NDT/IyMj/yYmJ/8ZGRj/VldZ/0NTff8BAwf/ExIR' ..
        '/w0ODv8GBwf/CwsL/x8fH/8lJCL/ISUp/WOSwf87W4BfAAAAAH9//wIAAAAAB6bS/xc6YIjtGyEn/xcWFv4VFQ//GR7C/yYu//8kK/z/hiQr//' ..
        '8WJCz+/yQp//8lMPr/SeVO/0//L/9O/jb/Tfs0/1P/OP8yoCP/AAAA/wIGAf8AAQD/FzcS/wkTCP8YTRH/VP85/038NP9O/zX/Ufw1/0L/Nv+S' ..
        'sC7//yQi//w1I/+I/zIj/xf8MSP//zUl/7UkGf8AAAD/IyEh/zMzM/8iIiL/JCQl/yQjIf8qLzz/Ehci/xUTEP8NDg//DAwM/xISEv8fHx//JS' ..
        'Um/yMhH/8kLDT/Y5PB/y1JZUkAAAAAf39/AgAAAAAH6f//DD5ok+McJC3/FxYX/h4eEv8VGqf/Jy7//yMq+/+GJCv//xYkLP7/JCn//yUw+v9J' ..
        '5U7/T/8v/07+Nv9O/jX/T/42/0nnMv8OLAr/AAAA/wABAP8ECAT/CBMG/zu6Kf9R/jf/Tf01/07/Nf9R/DX/Qv82/5KwLv//JCL//DUj/4j/Mi' ..
        'P/F/sxIv//Nib/mB0U/wAAAP8tKir/NDQ0/yIiIv8kJCT/JCQl/yIhIP8lJCP/IyMk/yAgIP8hISH/JCQk/yUlJf8kJSX/Ih8c/io3RP9klcT4' ..
        'EyY+NQAAAAAAf38CAAAAAAb///8CQGyZ1R8qNf8XFRb9FRQG/xMXh/8nLv//hyMq+/8PIyv6/yMo+/8kL/b/SOFN/077Lv9N+jX/Tfs0/0z6NP' ..
        '9P/TX/S+oz/xM7Dv8BAwH/BxcF/z7EKv9S/zj/TPkz/4FN+zT/BFD4NP9B+zX/kK0t//sjIf/4NCL/hvsxIv8I/DEj//8yI//7MSL//zYm/3kX' ..
        'EP8AAQL/NDAw/zMzM/8hISH/gSQkJP8CJiYm/yQkJP8jIyP/gSUlJf+BJCQk/wclJif/HhoX/jpPZP9zn8rlAAAHIQEAAAAAAAABAAAAACkCAQ' ..
        'AARHOgxSAuPP8ZFhb8EREE/w4RW/8mLf//JCv8/yYu//8oL///KjL//ygw//8qMf//KjL//ycu//8nL///KjD//ys3//9S+Vf/WP81/1j/Pv9W' ..
        '/zv/WP89/1X/Ov9Y/z3/Vf87/0zzNf9U/zv/V/87/1L/OP9V/zr/V/89/1T/Ov9X/zn/R/87/6DANf//JyX//zwp//85Kf//Oir//zkp//86Kv' ..
        '+C/zkp/w//NSX//zIj//wxI///NSX/UA4K/wAGB/82MzP/Li4u/yIiIv8lJSX/IyMj/x4eHv8jIyP/JiYm/yEhIf8iIiL/gSQkJP8HJSYn/xwY' ..
        'FPxGYXz/aJbDygAAAA0CAgIAAAAAAQAAAAA7AAAAAEd3qLMhMkT/GhYW/BMSCP8MDT7/JSz//yMq9v8RFXv/Cw5p/wAAW/8HCmX/AgVg/wAAWf' ..
        '8NEGv/DxNt/wABXf8CB17/EVQT/xVhCP8OWgT/FWEK/w9bBP8YZA7/FmEL/xpnD/8abA//EF8F/yBqFf8ibhf/HmoT/xFdBv8faxT/I2wX/xlq' ..
        'FP8vOwT/bQ8O/18JAf9eBgD/WwIA/18HAf9bAwD/XgYA/2EIAf9eBQD/iBoS//8zJP/+MiP//jMk/yYGA/8IEBH/ODY2/yoqKv8jIyP/IiIi/y' ..
        'QkJP9MTEz/bW1t/2pqav9ERET/gSIiIv8IJCQk/yYmJ/8bFxP8TW2O/1yLubUAAAADAgIDAAAAAAEAAAAANAAAAABSgrKgJDhO/xkVE/sTEw//' ..
        'Cgsc/yEo9f8kK/b/AAAA/xgYBv+fnpD/NTQl/2NjVP+Wlof/CQgA/wIBAP94eGj/U1JD/2pfav9cUF//iXyL/1pNW/+KfYz/LiIw/1JFVP84Kj' ..
        'n/QTND/4d6if8CAAT/AAAA/xEEE/+DdoX/DgEQ/wAAAP8TBRT/cW95/wADA/9XZWb/YnBx/32Mjf9ZaGn/eomK/1tqa/9XZGX/eIyO/ykODP/+' ..
        'MSH//zQl/9krHv8EAAD/Ghsb/zg4OP8pKSn/gSMjI/8PZWZm/62trv+hoaH/hoaF/2hoaP8eHh7/GBcX/yIiIv8mJyf/GRYT/FR5nv9YhK+eAA' ..
        'AAAP///wEAAAABAAAAAEQAAAAAW429gCpFYf8ZFhP7ExMV/wMDAf8cIcb/KC///wAABf+lpaP/2Njc/1paXf/x8fX/vLy//wwMEP8JCQz/9fX4' ..
        '///////Y2tj/xsnF/9ve2v+NkI3//////8THxP/DxsP/e357/6yuq///////NTg1/wEEAf9CRUL/9Pf0/zk8Of8CBQH/LjEu//Dw7v8GAgL/0s' ..
        '/P/8G9vf//////tLCw///+/f+UkZD/+fT0/5KYmP8xCgj//jIj//42Jv+SHBT/AAAB/yglJP84ODj/KSkp/xoaGf87Ojn/qail/6mopv+Kior/' ..
        'e3t7/2RkZf8uLS3/FxcX/xoaG/8mJib/Gxsb/GCKtP9QeaCCAAAAAH///wKBAAAAAEQAAAAAVY7DXy9Obv8ZFhP7FxYa/wIBAP8UGJP/KC///w' ..
        'AAAv+/v7v/vr6//1lZWf/i4uL/wMDB/yUlJv8FBQb/4ODg/7Gxsv/Hx8f/wcHA/8PDw/92d3b/5ubm/8/Pz/+/v7//lJWU/9LT0v/4+fj/eHl4' ..
        '/wABAP9lZmX/+Pn4/5OTk/8AAAD/Kywr/+jo6P8gHx//0dDQ/1lYWP/Ix8f/S0pK//f39/9fX1//kI6O/+vw8f9EHRr/+y0e//82J/9RDwr/AA' ..
        'YH/zAtLf84ODj/JCQk/zAxMv91d3v/k5eg/36Dj/9xcnL/ZWVl/1BQUP85OTn/ISEh/xMUFP8lIyL/ICQp/nCbxf9GYX9eAAAAAP///wGBAAAA' ..
        'ADoAAAAAXpbRSTFTd/8ZFxX8FxcZ/wkIAv8HCT3/Jy78/wAABv9JSUP/7u7s/1xcW/+qqqj/8fHv/yAgHv8EBAL/uLi2/0REQv+opqf/nJqc/8' ..
        'zKzP+JiIr/3t3f/3Jxc/98e3z/r66v/6Wkpf+Mioz/mJaY/wAAAP+AfoD/ycjJ/6Kho/8GBAb/Gxkb/9nZ2v+nqan/ra+v/05PUP+pq6v/QkND' ..
        '/9XX1/+lpqb/srGy/73Gx/84FRP/+zAh//MxI/8QAgH/DxMT/zU0NP84ODn/IyIh/zo/Sv82Ql//HyxM/xkjQP8TFBb/Dg4O/4EJCgr/BwgJCf' ..
        '8REhL/IyEf/iYvN/9nlMH+KURbQwAAAAB/f38CgQAAAAANAAAAAGKh1zQyV37/GBcY/hcWFv8SEhL/AAAC/xoftv8GByn/AAAA/wcHDv8AAAP/' ..
        'AAAE/wkJD/+BAQEH/yEEBAr/BAUK/wQJBf8ECQP/CQ4I/wYLBf8ECQP/AAAA/wMIAv8IDQj/AAMA/wAAAP8IDQf/AgcC/wMIAv8GCwX/CQ4I/w' ..
        'UKBP8BBwH/BwgF/wwGBv8JBAP/CAMC/woEA/8IAgL/CwYF/w0HB/8XERD/BAIC/zEHBP//Oin/jxwT/wAAAP8lIiL/gTg4OP8QJSUl/x4eHf8e' ..
        'HRr/FhUQ/xQSDv8SExL/EhMT/xISEv8NDg7/BwgI/xYXF/8iHxz+LTtI/2WUw/ILFiYuAAAAAAD//wGBAAAAAAoAAAAAf7/3IDVchPsZGx3/Fx' ..
        'YV/hgYGv8HBwP/BQct/yIo5f8iKOL/HSPc/4EgJ+L/Bx0j3/8gJuL/ICfh/x8j4f8gKt3/QMpE/0XhKf9D3y7/gUThLv8GR+Qx/0XiL/9D4C3/' ..
        'RuIv/0fkMf9D4C3/ReIv/4FE4S7/JEPgLf9H3y7/O+Iw/4CbKP/gHh3/3i4e/+EsH//gKx7/3ywe/90qHf/fKx3/5Soc//AvIf/iLyH/kx4V/w' ..
        'YAAP8QDw//Li0t/zo6Ov8zMzP/IyMj/yUlJf8mJif/ISEi/xsbHP8ZGRn/FhUV/w8QEP8HCAj/CgsL/yAhIv8fHBj9NUhb/2eWxOMAAAAdAQAA' ..
        'AAAAAAGBAAAAAAgAAAAA////CDxmkuIcIyr/GBYU/RkZGf8XFxn/AAAA/w8ScP+BKC///wAlLf//giUs//8FJS3//yUr//8mMf//S+xR/1L/Mf' ..
        '9R/zj/gVH/N/+BUP83/wBR/zf/gVD/N/8oUf83/1D/Nv9Q/zf/Uf83/1D/N/9T/zb/Q/83/5SzL///JSP//zYk//8zJP//NCX//zYm//84J///' ..
        'NSb/6TAi/54hF/8wCQb/AAAA/wgICP8jIiL/NTU1/zo6Ov8wMDD/IiIi/yUlJf8jIyP/Hx8f/xcWFv8PDw//CwwM/wcICP8MDAz/HBwc/yYnKP' ..
        '8bFxT8SmV//3CaxcYAAAAMAgICAAAAAAGBAAAAABQAAAABAQAAAEFwoMggLTn/GRcU/BgZGf8aGhv/ExMV/wEBAP8JCkb/GiC3/yMq8/8mLf//' ..
        'Jy7//yYt//8lLf//JCn//yUw+P9I4k3/Tfou/0z4Nf+ETPk0/4FM+jT/AE36NP+BTfs0/xFN/DT/Tv81/1P/Nv9F/zj/m7ox//8mJP//OCX//z' ..
        'Mk//IwIv/LKRz/hRsT/zwMCP8HAAD/AAAA/wACA/8UEhL/IyIi/zExMf+BOTk5/wEuLi7/IiIi/4IkJCT/DCAgIP8aGhr/FhYW/xkZGf8hISH/' ..
        'JSUl/yYmJ/8bFxT8VXib/12JtaMAAAABAgIDAAAAAAGBAAAAABQAVaoDAAAAAEN2q64kNUf/GhcU+xkZGv8ZGRn/Gxsb/xkZGv8LCwH/AgIA/w' ..
        'MEHf8ICkH/ERWD/xogvf8hKOT/JCn7/yYx/v9N71L/VP8y/1T/Ov+FVP85/wFT/zn/U/84/4FS/zj/CFH/N/9N+jT/Rtou/zTAKf9bcx7/fhEQ' ..
        '/0wRCv8xCQb/FwMC/4EAAAD/CgACAv8JCwv/GhgY/yQjI/8tLS3/NTU1/zk5Of83Nzf/Ojo6/ywsLP8iIiL/giQkJP+EJSUl/wYkJCT/JiYm/x' ..
        'oZF/xbhKv/UXqjiQAAAAB///8CggAAAAAhP3+/BAAAAABHfbOSJz5W/xoXFPsaGxz/Ghsb/xsbG/8dHR7/HyAi/xwcHf8UFA7/DAwB/wUEAP8C' ..
        'AQD/AgIM/wMEH/8FBy7/EToR/xhTDv8eZhT/JXsY/yeEGv8lexn/InMX/yBrFf8dYhP/G1oS/xhREP8VSQ7/E0EM/w82Cv8IHgX/AAIA/4IAAA' ..
        'D/EQAAAf8ABAX/BwsM/xQUFP8gHR3/JyUl/y0sLP8xMTH/NTU1/zk5Of84ODj/Nzc3/zg4Of87PDz/Kioq/yMjI/8kJCX/JCUl/4ElJSX/giUl' ..
        'Jv8HJSYm/yYmJ/8nJyf/HiAi/GOPuv9Ga45tAAAAAH///wKCAAAAABc/f78EAAAAAFCJw28oRWL9EQoD+RUTEf4WFBL+FxYU/hoYF/4bGhn+HR' ..
        '0c/yAfIP8iIiT/ISEk/yAgIf8cHBn/FhYQ/xISCf8NBQ3/CQAL/wYACP8EAAf/BAAG/wMABf+BAgAF/w8DAAX/BAAG/wUACP8HAAn/CQAL/wsD' ..
        'Df8PChH/FBMV/xgaGf8fHx7/JyQl/yspKf8uLCz/MC8v/zMzM/83Nzf/gTg4OP8BOTk5/zs7O/+COjo6/wI9PDz/PTw7/yYlJf6BIiEg/g0hHx' ..
        '7+IB4c/h8dG/4eHBr+HhsZ/R0aGP0cGRf9GxkX/RkTDvwcJCz8b5zI+yxIYEoAAAAA////AYIAAAAADVWqqgMAAAAAUo3IQUFrlf9ATVv/PUpX' ..
        '/zpDTv82P0f/Mzk//y4zOP8sLjH/Kywt/yoqK/8nJyf+gicmJv4NJyYm/SkpJf0pKST9KSok/SgpI/0nKCP9Jygi/ScnIv0nJyH9Jyci/ScoIv' ..
        '0oKCP9KSgj/SkpJP2BKikl/YErKSb9ACwpJ/2BLCon/R0sKij9Kyko/SwqKP0rKSf9Kyko/isqKP4rKSj+Kyop/isqKv4sKyv/LCws/ywtLv8s' ..
        'LjD/Jicp/ygrLv8rLzT/MTY8/zY8Q/85QUr/PEVO/z5JVP9DT1v/R1Vj/0xcbP9OX3D/ZoGc/3agyvkFCxcrAQAAAAAA/wGCAAAAABt/f38CAA' ..
        'AAAER1phpMgLLHXY/C3F6QwuJgkMHpYZDA7maSwPNmkrz2aJC3+2WNtv9jjbb/ZY22/2eOtf9ljLP/Zoyy/2iNs/9ojLD/aIuv/2iMsP9mi7D/' ..
        'Z4uv/2iKrf9oiqz/aYqs/2mLrf9piqz/gWmKq/+Baoqq/wJpiqr/aYqr/2mKrP+Caous/x1qjK7/a4yu/2yNr/9sjbD/bI6w/22Psf9sj7L/bY' ..
        '+x/22Qs/9tkLT/b5G0/3CSs/1zlbb7epu79nudvvN+oMLyf6PI7n2jyet3oMjocp3G5XGbxt9ynMfbcJzH1XCbxtBumsbIcp3IwUtzmaYAAAAZ' ..
        'AAAAAAAAAAGCAAAAAIIAAAAAFAAAAAMAAAAXAAAAHQAGFCYAFy4sDiZDNRk2Uz0sS2pKMVJ3UzJZgFs2YIdiOGKLaDtkjms+Z5NvQWyWdURsln' ..
        'hFbZd5RG+be0RxnX5FcZ2AR3KggYFIc6CCAUp1oIJKdaKCgUp3ooKCTHeigh1Kd6KCTXaigU13o4BMdqJ/THegfEt1nHpLc5t5SHOcd0hymXRG' ..
        'bZZwRGyUbENskmpCao9nQWiMYjxjh1w9YINXOVl1UDdSbkomQWBCGThWOxcuSjcFHzQxABEjKwAAEycAAAAiAAAAHQAAABkAAAAUAAAAEAAAAA' ..
        'yCAAAAB4QAAAAA'
    ),
    ['PixelGroupStore/swatch_pix1.tga'] = (

        'AAAKAAAAAAAAAAAAIAAgACAon/8zqf+f/zOp/5//M6n/n/8zqf+f/zOp/5//M6n/n/8zqf+f/zOp/5//M6n/n/8zqf+f/zOp/5//M6n/n/8zqf' ..
        '+f/zOp/5//M6n/n/8zqf+f/zOp/5//M6n/n/8zqf+f/zOp/5//M6n/n/8zqf+f/zOp/5//M6n/n/8zqf+f/zOp/5//M6n/n/8zqf+f/zOp/5//' ..
        'M6n/n/8zqf+f/zOp/w=='
    ),
    ['PixelGroupStore/swatch_pix2.tga'] = (

        'AAAKAAAAAAAAAAAAIAAgACAonzOZ//+fM5n//58zmf//nzOZ//+fM5n//58zmf//nzOZ//+fM5n//58zmf//nzOZ//+fM5n//58zmf//nzOZ//' ..
        '+fM5n//58zmf//nzOZ//+fM5n//58zmf//nzOZ//+fM5n//58zmf//nzOZ//+fM5n//58zmf//nzOZ//+fM5n//58zmf//nzOZ//+fM5n//58z' ..
        'mf//nzOZ//+fM5n//w=='
    ),
    ['PixelGroupStore/swatch_pix3.tga'] = (

        'AAAKAAAAAAAAAAAAIAAgACAon5n/M/+fmf8z/5+Z/zP/n5n/M/+fmf8z/5+Z/zP/n5n/M/+fmf8z/5+Z/zP/n5n/M/+fmf8z/5+Z/zP/n5n/M/' ..
        '+fmf8z/5+Z/zP/n5n/M/+fmf8z/5+Z/zP/n5n/M/+fmf8z/5+Z/zP/n5n/M/+fmf8z/5+Z/zP/n5n/M/+fmf8z/5+Z/zP/n5n/M/+fmf8z/5+Z' ..
        '/zP/n5n/M/+fmf8z/w=='
    ),
}

local B64_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

local function base64Decode(data)
    local bytes = {}
    local bits, bitCount = 0, 0
    for i = 1, #data do
        local c = data:sub(i, i)
        if c == '=' then
            break
        end
        local idx = B64_CHARS:find(c, 1, true)
        if idx ~= nil then
            bits = bits * 64 + (idx - 1)
            bitCount = bitCount + 6
            if bitCount >= 8 then
                local shift = bitCount - 8
                local byte = math.floor(bits / (2 ^ shift))
                bytes[#bytes + 1] = string.char(byte % 256)
                bits = bits % (2 ^ shift)
                bitCount = shift
            end
        end
    end
    return table.concat(bytes)
end

local function fileExists(path)
    local f = io.open(path, 'rb')
    if f ~= nil then
        f:close()
        return true
    end
    return false
end

-- mkdir syntax differs by platform (HostOS() confirmed working elsewhere).
local function ensureDirectory(dirPath)
    local okHost, host = pcall(HostOS)
    local cmd
    if okHost and host == 'Windows' then
        cmd = 'mkdir "' .. dirPath .. '"'
    else
        cmd = 'mkdir -p "' .. dirPath .. '"'
    end
    pcall(function() os.execute(cmd) end)
end

-- Writes relativeFileName under GetPath(Enums.PathType.Textures) from
-- EMBEDDED_TEXTURES if it isn't already there. Idempotent. .fileName is
-- always relative to GetPath(Enums.PathType.Textures), never prefixed with
-- it - an absolute path there doubles up and fails to load (confirmed live
-- on both Mac and Windows onPC in earlier plugins).
local function ensureTextureFileOnDisk(relativeFileName)
    local okPath, texturesRoot = pcall(function() return GetPath(Enums.PathType.Textures) end)
    if not okPath or texturesRoot == nil then
        Printf('PGS asset debug: GetPath(Enums.PathType.Textures) failed err=%s', tostring(texturesRoot))
        return false
    end

    local fullPath = texturesRoot .. '/' .. relativeFileName
    if fileExists(fullPath) then
        return true
    end

    local subDir = relativeFileName:match('^(.+)/[^/]+$')
    if subDir ~= nil then
        ensureDirectory(texturesRoot .. '/' .. subDir)
    end

    local data = EMBEDDED_TEXTURES[relativeFileName]
    if data == nil then
        Printf('PGS asset debug: no embedded data for %s', relativeFileName)
        return false
    end

    local okDecode, decoded = pcall(base64Decode, data)
    if not okDecode or decoded == nil then
        Printf('PGS asset debug: base64Decode failed for %s err=%s', relativeFileName, tostring(decoded))
        return false
    end

    local okOpen, f = pcall(io.open, fullPath, 'wb')
    if not okOpen or f == nil then
        Printf('PGS asset debug: could not open %s for writing', fullPath)
        return false
    end

    f:write(decoded)
    f:close()
    Printf('PGS asset debug: wrote %s (%d bytes)', fullPath, #decoded)
    return true
end

local function ensureTexture(textureName, fileName)
    ensureTextureFileOnDisk(fileName)

    local okTextures, textures = pcall(function() return Root().GraphicsRoot.TextureCollect.Textures end)
    if not okTextures or textures == nil then
        Printf('PGS texture debug: could not access TextureCollect.Textures ok=%s', tostring(okTextures))
        return nil
    end

    local okFind, existing = pcall(function() return textures[textureName] end)
    local tex = (okFind and existing ~= nil) and existing or nil

    if tex == nil then
        local okAppend, newTex = pcall(function() return textures:Append('Texture') end)
        if not okAppend or newTex == nil then
            Printf('PGS texture debug: textures:Append(Texture) failed for %s ok=%s val=%s', textureName, tostring(okAppend), tostring(newTex))
            return nil
        end
        tex = newTex
    end

    local okSet, setErr = pcall(function()
        tex.name = textureName
        tex.fileName = fileName
    end)
    if not okSet then
        Printf('PGS texture debug: setting name/fileName failed for %s err=%s', textureName, tostring(setErr))
        return nil
    end

    return textureName
end

local function ensureLogoTexture()
    return ensureTexture(LOGO_TEXTURE_NAME, LOGO_TEXTURE_FILE)
end

local function ensureSwatchTexture(pixNum)
    local textureName = 'PixelGroupStore_Swatch' .. tostring(pixNum)
    local fileName = SWATCH_FILES[pixNum]
    if fileName == nil then
        return nil
    end
    return ensureTexture(textureName, fileName)
end

-- ===================================================================
-- Custom single-choice popup: CG-branded window with one colored (or
-- plain) button per choice. Clicking a button immediately selects it
-- and closes the window - no separate Apply step, same immediate-close
-- pattern as SaveShowAs2/3's YES/NO buttons. Returns the chosen value,
-- or nil if cancelled via the titlebar close button.
-- ===================================================================

local pgsSignalCounter = 0

local function choicePopup(display_handle, titleText, choices)
    local chosenValue = nil
    local cancelled = false
    local continue = false

    local baseInput = GetFocusDisplay().ScreenOverlay:Append('BaseInput')
    baseInput.Name = 'PixelGroupStoreWindow'
    baseInput.H = 0
    baseInput.W = 650
    baseInput.Columns = 1
    baseInput.Rows = 2
    baseInput[1][1].SizePolicy = 'Fixed'
    baseInput[1][1].Size = 60
    baseInput[1][2].SizePolicy = 'Stretch'
    baseInput.AutoClose = 'No'
    baseInput.CloseOnEscape = 'Yes'

    local titleBar = baseInput:Append('TitleBar')
    titleBar.Columns = 2
    titleBar.Rows = 1
    titleBar.Anchors = '0,0'
    titleBar[2][2].SizePolicy = 'Fixed'
    titleBar[2][2].Size = 50
    titleBar.Texture = 'corner2'

    local titleBarIcon = titleBar:Append('TitleButton')
    titleBarIcon.Text = titleText
    titleBarIcon.Texture = 'corner1'
    titleBarIcon.Anchors = '0,0'
    titleBarIcon.Icon = ensureLogoTexture() or 'star'

    local titleBarCloseButton = titleBar:Append('CloseButton')
    titleBarCloseButton.Anchors = '1,0'
    titleBarCloseButton.Texture = 'corner2'
    titleBarCloseButton.PluginComponent = my_handle
    titleBarCloseButton.Clicked = 'PGS_CloseClicked'

    local dlgFrame = baseInput:Append('DialogFrame')
    dlgFrame.H = '100%'
    dlgFrame.W = '100%'
    dlgFrame.Columns = 1
    dlgFrame.Rows = 1
    dlgFrame.Anchors = '0,1'
    dlgFrame[1][1].SizePolicy = 'Stretch'

    local buttonGrid = dlgFrame:Append('UILayoutGrid')
    buttonGrid.Columns = 1
    buttonGrid.Rows = #choices
    buttonGrid.Anchors = '0,0'
    for i = 1, #choices do
        buttonGrid[1][i].SizePolicy = 'Fixed'
        buttonGrid[1][i].Size = 50
    end

    for i, choice in ipairs(choices) do
        local btn = buttonGrid:Append('Button')
        btn.Anchors = { top = i - 1, bottom = i - 1, left = 0, right = 0 }
        btn.Textshadow = 1
        btn.HasHover = 'Yes'
        btn.Text = choice.label
        btn.Font = 'Medium20'
        btn.TextalignmentH = 'Centre'
        btn.PluginComponent = my_handle
        if choice.swatchNum ~= nil then
            btn.Texture = ensureSwatchTexture(choice.swatchNum)
        end

        pgsSignalCounter = pgsSignalCounter + 1
        local signalName = 'PGS_ChoiceClicked_' .. pgsSignalCounter
        btn.Clicked = signalName
        signalTable[signalName] = function(caller)
            GetFocusDisplay().ScreenOverlay:ClearUIChildren()
            chosenValue = choice.value
            continue = true
        end
    end

    signalTable.PGS_CloseClicked = function(caller)
        GetFocusDisplay().ScreenOverlay:ClearUIChildren()
        cancelled = true
        continue = true
    end

    repeat until continue

    if cancelled then
        return nil
    end
    return chosenValue
end

-- Pink-styled stand-in for Confirm() - Confirm() itself has no backColor
-- param (confirmed elsewhere: it only ever shows fixed OK/Cancel with no
-- theming hook), but stock MessageBox does, so a single-OK-button
-- MessageBox with backColor = 'Window.Plugins' gives the same pink used
-- everywhere else in this plugin for a plain info/error popup.
local function pinkConfirm(title, message)
    MessageBox({
        icon = ensureLogoTexture() or 'object_smart',
        backColor = 'Window.Plugins',
        title = title,
        message = message,
        commands = { { value = 1, name = 'OK' } },
    })
end

-- ===================================================================
-- Config
-- ===================================================================

local FIXTURE_TYPES = {
    { label = "PIXEL LINE IP", value = "PIXEL LINE IP" },
    { label = "JDC 68 CH",    value = "JDC 68 CH" },
    { label = "STRIKE M 97 CH", value = "STRIKE M 97 CH" },
}

local RGB_GROUPS = {
    { label = "PIXEL1 RGB PIXELS GRID", value = "PIXEL1 RGB PIXELS GRID", swatchNum = 1 },
    { label = "PIXEL2 RGB PIXELS GRID", value = "PIXEL2 RGB PIXELS GRID", swatchNum = 2 },
    { label = "PIXEL3 RGB PIXELS GRID", value = "PIXEL3 RGB PIXELS GRID", swatchNum = 3 },
}

local WHITE_GROUPS = {
    { label = "PIXEL1 WHITE PIXELS GRID", value = "PIXEL1 WHITE PIXELS GRID", swatchNum = 1 },
    { label = "PIXEL2 WHITE PIXELS GRID", value = "PIXEL2 WHITE PIXELS GRID", swatchNum = 2 },
    { label = "PIXEL3 WHITE PIXELS GRID", value = "PIXEL3 WHITE PIXELS GRID", swatchNum = 3 },
}

-- Per fixture-type, per-color "section" descriptor:
--   prefix(fixtureNum)  -> address prefix before the final ".<pixel>"
--   rows                -> ordered list of {startPixel, endPixel} - one
--                          entry per grid row, in top-to-bottom order.
--                          Ranges are a CLEAN split (no shared boundary
--                          pixel between rows).
--   colWidth             -> columns one fixture's row occupies, used to
--                          space fixtures apart within a truss.
--
-- STRIKE M 97 CH (user-confirmed, 2026-09-01): nested part.pixel
-- addressing, part 1 = RGB (14 pixels, split 7/7), part 2 = White (28
-- pixels, split 14/14) - e.g. "401.1.1 Thru 7" / "401.1.8 Thru 14".
--
-- JDC 68 CH (user-confirmed, 2026-09-01): flat addressing, no part number -
-- pixels 1-12 = RGB (split 6/6, e.g. "701.1 Thru 6" / "701.7 Thru 12"),
-- pixels 13-24 = White, all in ONE row, no split (e.g. "701.13 Thru 24").
local FIXTURE_PROFILES = {
    ["STRIKE M 97 CH"] = {
        rgb = {
            prefix = function(n) return n .. ".1" end,
            rows = { { 1, 7 }, { 8, 14 } },
            colWidth = 7,
        },
        white = {
            prefix = function(n) return n .. ".2" end,
            rows = { { 1, 14 }, { 15, 28 } },
            colWidth = 14,
        },
    },
    ["JDC 68 CH"] = {
        rgb = {
            prefix = function(n) return n end,
            rows = { { 1, 6 }, { 7, 12 } },
            colWidth = 6,
        },
        white = {
            prefix = function(n) return n end,
            rows = { { 13, 24 } },
            colWidth = 12,
        },
    },
    -- PIXEL LINE IP not set up yet - no profile, Main() shows a "not set up"
    -- message until the addressing details are provided.
}

-- Per-fixture command sequence, confirmed live 2026-09-01 via the console's
-- own Command Line History as three SEPARATE commands (all OK) - a combined
-- "Grid X/Y Fixture ... Thru ..." line reports OK but does NOT actually
-- place the pixels, and "Please" combined with an explicit Thru range is
-- "Not implemented". So every placement below is its own Cmd() call, one
-- Grid + one Fixture pair per row in the section:
--   Grid <col>/<rowTop + rowIndex>
--   Fixture <prefix>.<startPixel> Thru <endPixel>
local function arrangeFixture(section, fixtureNum, col, rowTop)
    local prefix = section.prefix(fixtureNum)
    for i, range in ipairs(section.rows) do
        Cmd(string.format("Grid %d/%d", col, rowTop + i - 1))
        Cmd(string.format("Fixture %s.%d Thru %d", prefix, range[1], range[2]))
    end
end

-- Store uses /o (the target group always exists and should be overwritten)
-- and /nc (plugins run off the UI thread, so a normal confirmation dialog
-- can't render and would otherwise silently auto-cancel the command - see
-- GroupCleanupV4 notes). One Store per section covering the whole
-- selection, regardless of how many fixtures were just arranged.
--
-- Multi-fixture ranges (2026-09-01, UNTESTED beyond a single fixture at
-- col 0): truss index = floor(fixture index / fixturesPerTruss) picks the
-- row block (rowTop = truss * #section.rows), position-within-truss picks
-- the column block (col = posInTruss * section.colWidth, wide enough that
-- fixtures never overlap). Check the Selection Grid after the first
-- multi-fixture run before trusting the Store step.
local function arrangeAndStore(display_handle, fixtureList, fixturesPerTruss, section, groupChoices, popupTitle)
    for i, fixtureNum in ipairs(fixtureList) do
        local idx = i - 1
        local truss = math.floor(idx / fixturesPerTruss)
        local posInTruss = idx % fixturesPerTruss
        local col = posInTruss * section.colWidth
        local rowTop = truss * #section.rows
        arrangeFixture(section, fixtureNum, col, rowTop)
    end

    local groupName = choicePopup(display_handle, popupTitle, groupChoices)
    if groupName == nil then
        Printf("PixelGroupStore: cancelled before storing")
        return false
    end

    Cmd(string.format("Store Group '%s' /o /nc", groupName))
    Printf("PixelGroupStore: stored %d fixture(s) into Group '%s'", #fixtureList, groupName)
    return true
end

-- Parses "401" (single fixture) or "401 Thru 410" (inclusive range) into a
-- list of fixture-number strings. Anything else returns nil.
local function parseFixtureRange(input)
    local a, b = input:match("^%s*(%d+)%s*[Tt][Hh][Rr][Uu]%s*(%d+)%s*$")
    if a ~= nil and b ~= nil then
        local startNum, endNum = tonumber(a), tonumber(b)
        if startNum ~= nil and endNum ~= nil and startNum <= endNum then
            local list = {}
            for n = startNum, endNum do
                table.insert(list, tostring(n))
            end
            return list
        end
        return nil
    end

    local single = input:match("^%s*(%d+)%s*$")
    if single ~= nil then
        return { single }
    end

    return nil
end

-- ===================================================================
-- Main
-- ===================================================================

local function Main(display_handle, arguments)
    local fixtureType = choicePopup(display_handle, "What strobey boi are we using today?", FIXTURE_TYPES)
    if fixtureType == nil then
        Printf("PixelGroupStore: cancelled")
        return
    end

    local profile = FIXTURE_PROFILES[fixtureType]
    if profile == nil then
        pinkConfirm("PixelGroupStore", fixtureType .. " isn't set up yet.")
        return
    end

    local fixtureInput = TextInput("Fixture number (e.g. 401 or 401 Thru 410)", "")
    if fixtureInput == nil or fixtureInput == "" then
        Printf("PixelGroupStore: cancelled")
        return
    end

    local fixtureList = parseFixtureRange(fixtureInput)
    if fixtureList == nil or #fixtureList == 0 then
        pinkConfirm("PixelGroupStore", "Couldn't understand '" .. fixtureInput .. "' - use a single number (401) or a range (401 Thru 410).")
        return
    end

    local fixturesPerTruss = 1
    if #fixtureList > 1 then
        local perTrussInput = TextInput("Fixtures per truss", "")
        local perTruss = perTrussInput ~= nil and tonumber(perTrussInput) or nil
        if perTruss == nil or perTruss < 1 then
            Printf("PixelGroupStore: cancelled")
            return
        end

        local trussCountInput = TextInput("Number of trusses", "")
        local trussCount = trussCountInput ~= nil and tonumber(trussCountInput) or nil
        if trussCount == nil or trussCount < 1 then
            Printf("PixelGroupStore: cancelled")
            return
        end

        fixturesPerTruss = math.floor(perTruss)
        if fixturesPerTruss * math.floor(trussCount) ~= #fixtureList then
            Printf("PixelGroupStore: warning - %d fixture(s) selected but %d per truss x %d trusses = %d",
                #fixtureList, fixturesPerTruss, math.floor(trussCount), fixturesPerTruss * math.floor(trussCount))
        end
    end

    if not arrangeAndStore(display_handle, fixtureList, fixturesPerTruss, profile.rgb, RGB_GROUPS, "Store RGB pixels into which group?") then
        return
    end

    if not arrangeAndStore(display_handle, fixtureList, fixturesPerTruss, profile.white, WHITE_GROUPS, "Store White pixels into which group?") then
        return
    end

    -- Clear the programmer after the White store, same as pressing Clear
    -- three times by hand.
    Cmd("Clear")
    Cmd("Clear")
    Cmd("Clear")
end

return Main
