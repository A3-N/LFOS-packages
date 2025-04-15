#!/bin/bash
for dir in getfreaky lf-stackmask; do
  pushd "$dir"
  makepkg -f -c  # -f = force rebuild, -c = clean afterward
  mv *.pkg.tar.zst ../repo/
  popd
done

# rm repo/lfos.db repo/lfos.files
# cp repo/lfos.db.tar.gz repo/lfos.db
# cp repo/lfos.files.tar.gz repo/lfos.files

# cp lfos.files.tar.gz lfos.files
# rm lfos.files.tar.gz
