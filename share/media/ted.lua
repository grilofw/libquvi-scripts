-- libquvi-scripts
-- Copyright (C) 2012,2013  Toni Gundogdu <legatvs@gmail.com>
-- Copyright (C) 2011  Bastien Nocera <hadess@hadess.net>
--
-- This file is part of libquvi-scripts <http://quvi.sourceforge.net/>.
--
-- This program is free software: you can redistribute it and/or
-- modify it under the terms of the GNU Affero General Public
-- License as published by the Free Software Foundation, either
-- version 3 of the License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Affero General Public License for more details.
--
-- You should have received a copy of the GNU Affero General
-- Public License along with this program.  If not, see
-- <http://www.gnu.org/licenses/>.
--

local Ted = {} -- Utility functions unique to this script

-- Identify the media script.
function ident(qargs)
  return {
    can_parse_url = Ted.can_parse_url(qargs),
    domains = table.concat({'ted.com'}, ',')
  }
end

-- Parse the media properties.
function parse(qargs)
  local p = quvi.http.fetch(qargs.input_url).data

  if not Ted.chk_ext(qargs, p) then
    qargs.title = p:match('<title>(.-)%s+|') or ''
  end

  return qargs
end

--
-- Utility functions
--

function Ted.can_parse_url(qargs)
  local U = require 'socket.url'
  local t = U.parse(qargs.input_url)
  if t and t.scheme and t.scheme:lower():match('^http$')
       and t.host   and t.host:lower():match('^www.ted%.com$')
       and t.path   and t.path:lower():match('^/talks/.+$')
  then
    return true
  else
    return false
  end
end

function Ted.chk_ext(qargs, p)
  Ted.iter_streams(qargs, p)
  if #qargs.streams >0 then -- Self-hosted media.
    return false
  else -- External media. Try the first iframe.
    qargs.goto_url = p:match('<iframe src="(.-)"') or ''
    if #qargs.goto_url >0 then
      return true
    else
      error('no match: media stream URL')
    end
  end
end

function Ted.iter_streams(qargs, p)
  qargs.streams = {}

  local d = p:match('talkPage.init",(.-)%)<') or ''
  if #d == 0 then return end

  local S = require 'quvi/stream'
  local J = require 'json'
  local j = J.decode(d)

  --Ted.rtmp_streams(qargs, S, J, j)
  Ted.native_downloads(qargs, S, J, j)

  for _,v in pairs(j['talks']) do
    qargs.duration_ms = tonumber(v['duration'] or 0) * 1000
    qargs.thumb_url = v['thumbs'] or ''
    qargs.id = v['id'] or ''
  end
  if #qargs.streams >1 then
    Ted.ch_best(qargs, S)
  end
end

-- this correctly identifies the rtmp URLs but leads to
-- "error: protocol `rtmp` is not supported" on quvi get.
--
-- This is unfortunate as the rtmp streams provide better
-- resolution than the native downloads
function Ted.rtmp_streams(qargs, S, J, j)
  for _,v in pairs(j['talks']) do
    local s = v['streamer'] or error('no match: streamer')

    for _,vv in pairs(v['resources']['rtmp']) do
      local u = table.concat({s,vv['file']:match('^%w+:(.-)$')},'/')
      local t = S.stream_new(u)

      t.video.bitrate_kbit_s = tonumber(vv['bitrate'] or 0)
      t.video.height = tonumber(vv['height'] or 0)
      t.video.width = tonumber(vv['width'] or 0)

      t.container = vv['file']:match('^(%w+):') or ''
      t.id = Ted.rtmp_stream_id(t)

      table.insert(qargs.streams, t)
    end
  end
end

-- this identifies the highest format native (HTTP)
-- download, which unfortunately is of lower quality than
-- the rtmp streams
function Ted.native_downloads(qargs, S, J, j)
  for _,v in pairs(j['talks']) do
    local u = v['nativeDownloads']['high']
    local t = S.stream_new(u)
    t.video.height = tonumber(u:match('-(%d+)p%.') or 0)
    table.insert(qargs.streams, t)
  end 
end

function Ted.rtmp_stream_id(t)
  return string.format('%s_%dk_%dp',
      t.container, t.video.bitrate_kbit_s, t.video.height)
end

function Ted.ch_best(qargs, S)
  local r = qargs.streams[1] -- Make the first one the 'best' by default.
  r.flags.best = true
  for _,v in pairs(qargs.streams) do
    if v.video.height > r.video.height then
      r = S.swap_best(r,v)
    end
  end
end

-- vim: set ts=2 sw=2 tw=72 expandtab:
