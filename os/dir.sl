# Directory handling routines

# encode (name,blknum) into a dirent at the given dirent address
# "name" has max. length of 30 characters
# example:
#    dirent(BLKBUF+4, "foo.txt", 1234)
var dirent = func(dirent, name, blknum) {
    var s = name;
    var i = 0;

    while (1) {
        *(dirent+i) = shl(*s, 8);
        if (!*s) break;
        s++;

        *(dirent+i) = dirent[i] | (*s & 0xff);
        if (!*s) break;
        s++;

        i++;
        if (i == 16) throw(TOOLONG);
    };

    *(dirent+15) = blknum;
};

# decode the dirent starting at dirent into a name and block number;
# store a pointer to a (static) string containing the name in *pname,
# and store the block number in *pblknum
var undirent = func(dirent, pname, pblknum) {
    var p = dirent;
    var s = undirent_str;

    while (p != dirent+16) {
        *s = shr8(*p); # high byte
        if (!*s) break;
        s++;

        *s = *p & 0xff; # low byte
        if (!*s) break;
        s++;

        p++;
    };

    *s = 0; # nul-terminate even if the name in the dirent used all 30 chars

    *pname = undirent_str;
    *pblknum = dirent[15];
};

# call cb(name, blknum, dirblknum, dirent_offset) for every entry in the
# directory starting at "dirblk"; callback arguments are:
#   name:          file/directory name (this will be "" for unallocated dirents)
#   blknum:        block number that this name is linked to
#   dirblknum:     number of directory block that this name is in
#   dirent_offset: word offset of the dirent for this name in "dirblknum"
# cb() should return 1 to continue searching or 0 to bail early
var dirwalk = func(dirblk, cb) {
    var off = 2;
    var name;
    var blknum;
    var next;
    while (1) {
        blkread(dirblk);
        if (blktype() != TYPE_DIR) throw(NOTDIR);
        next = blknext();

        while (off < BLKSZ) {
            undirent(BLKBUF+off, &name, &blknum);
            if (cb(name, blknum, dirblk, off) == 0) return 0;
            off = off + DIRENTSZ;
        };

        # proceed to next block in this directory, if there is one
        if (!next) break;
        dirblk = next;
    };
    kputs("dirwalk completes\n");
};

# find the given name in dirblk, traversing directories as necessary
# return a pointer to a static list:
#  [
#    blknum,        # the block number that the name links to
#    dirblknum,     # the block number that the name was found in
#    dirent_offset, # the word offset of the dirent for this name
#  ]
# return a null pointer if not found
var dfr_offset;
var dfr_findname;
var dfr_blknum;
var dirfindname = func(dirblk, findname) {
    dfr_findname = findname;
    while (*dfr_findname == '/') dfr_findname++;

    while (1) {
        dfr_blknum = 0;

        dirwalk(dirblk, func(name, blknum, dirblknum, dirent_offset) {
            if (*name && pathbegins(dfr_findname, name)) {
                while (*dfr_findname && *dfr_findname != '/') dfr_findname++;
                dfr_blknum = blknum;
                return 0; # found it
            } else {
                return 1; # keep searching
            };
        });

        if (dfr_blknum == 0) return 0;

        while (*dfr_findname == '/') dfr_findname++;
        if (*dfr_findname == 0) break;

        dirblk = dfr_blknum;
    };

    return [dfr_blknum, dirblk, dfr_offset];
};

