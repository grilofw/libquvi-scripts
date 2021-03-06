/* libquvi-scripts
 * Copyright (C) 2012  Toni Gundogdu <legatvs@gmail.com>
 *
 * This file is part of libquvi-scripts <http://quvi.sourceforge.net>.
 *
 * This program is free software: you can redistribute it and/or
 * modify it under the terms of the GNU Affero General Public
 * License as published by the Free Software Foundation, either
 * version 3 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General
 * Public License along with this program.  If not, see
 * <http://www.gnu.org/licenses/>.
 */

#include "config.h"

#include <string.h>
#include <glib.h>
#include <quvi.h>

#include "tests.h"

static const gchar *URLs[] =
{
  "http://www.gaskrank.tv/tv/motorrad-oldtimer/1928-henderson-deluxe-alt-und--19115.htm",
  "http://www.gaskrank.tv/tv/rennstrecken/idm-streckenvorstellung-schleiz-von-michael-ranseder.htm",
  NULL
};

static const gchar *TITLEs[] =
{
  "1928 Henderson Deluxe - alt und mit der Patina des Alters aber läuft",
  "IDM Streckenvorstellung Schleiz von Michael Ranseder",
  NULL
};

static const gchar *IDs[] =
{
  "19115",
  "19746",
  NULL
};

static void test_media_gaskrank()
{
  struct qm_test_exact_s e;
  struct qm_test_opts_s o;
  gint i;

  for (i=0; URLs[i] != NULL; ++i)
    {
      memset(&e, 0, sizeof(e));
      memset(&o, 0, sizeof(o));

      e.title = TITLEs[i];
      e.id = IDs[i];

      qm_test(__func__, URLs[i], &e, &o);
    }
}

gint main(gint argc, gchar **argv)
{
  g_test_init(&argc, &argv, NULL);
  g_test_add_func("/media/gaskrank", test_media_gaskrank);
  return (g_test_run());
}

/* vim: set ts=2 sw=2 tw=72 expandtab: */
