#!/bin/bash

# Restore files from commit be22674
git checkout be22674f8c1ac84e1cff89947ff4a6753070f21b~1 -- \
  src/core/crypto/crypto.cpp \
  src/core/crypto/crypto.h \
  src/core/crypto/keys.h \
  src/core/file_format/pkg.h \
  src/core/file_format/pkg_type.cpp \
  src/core/file_format/pkg_type.h \
  src/qt_gui/pkg_viewer.cpp \
  src/qt_gui/pkg_viewer.h

# Restore files from commit 31e1d4f
git checkout 31e1d4f839118b59398ca6f871929fc0e286e13c~1 -- \
  documents/Quickstart/2.png \
  src/core/file_format/pkg.cpp \
  src/core/loader.cpp \
  src/core/loader.h \
  src/qt_gui/install_dir_select.cpp \
  src/qt_gui/install_dir_select.h

# Restore files from commit a5958bf
git checkout a5958bf7f0da207e02065a88355b8afae0b5e256~1 -- \
  cmake/Findcryptopp.cmake

echo "Files restored successfully!"
