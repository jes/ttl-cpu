# buffered i/o lib
#
# bio structure:
# 0:   fd (length = 1)
# 1:   buflen (1)
# 2:   bufpos (1)
# 3:   mode (1)
# 4..: buffer (BIO_BUFSZ)

include "stdio.sl";
include "malloc.sl";

var BIO_BUFSZ = 254; # align with block size on disk

# "mode" should be O_READ or O_WRITE
var bfdopen = func(fd, mode) {
    var bio = malloc(BIO_BUFSZ + 4);
    *bio = fd;
    *(bio+1) = 0;
    *(bio+2) = 0;
    *(bio+3) = mode;

    return bio;
};

# "mode" should be O_READ or O_WRITE
var bopen = func(file, mode) {
    var fd = open(file, mode);
    if (fd < 0) return 0;
    return bfdopen(fd, mode);
};

var bflush = func(bio) {
    var fd = bio[0];
    var bufpos = bio[2];
    var mode = bio[3];

    if (!(mode & O_WRITE)) return 0;

    # TODO: [bug] error-check?
    write(fd, bio+4, bufpos);
    *(bio+2) = 0;
};

# free without closing the underlying fd
var bfree = func(bio) {
    bflush(bio);
    free(bio);
};

var bclose = func(bio) {
    var fd = bio[0];
    bfree(bio);
    close(fd);
};

var bread = func(bio, buf, sz) {
    fprintf(2, "bread() not implemented yet\n", 0);
};

var bwrite = func(bio, buf, sz) {
    fprintf(2, "bwrite() not implemented yet\n", 0);
};

# grab a new block of data from bio (internal; not for library users)
var _bslurp = func(bio) {
    var fd = bio[0];

    *(bio+2) = 0; # bufpos
    *(bio+1) = read(fd, bio+4, BIO_BUFSZ);
    if (bio[1] < 0) {
        fprintf(2, "bread %d: %s\n", [fd, strerror(bio[1])]);
        *(bio+1) = 0;
    };
};

#var bgetc = func(bio) {
#    var buflen = bio[1];
#    var bufpos = bio[2];
#    if (bufpos == buflen) _bslurp(bio);
#    buflen = bio[1];
#    bufpos = bio[2];
#    if (buflen == 0) return EOF;
#    var ch = *(bio+4+bufpos);
#    *(bio+2) = bufpos+1;
#    return ch;
#};
#
# usage: bgetc(bio)
var bgetc = asm {
    pop x
    ld (_bgetc_bio), x # bio

    inc x
    ld r2, (x) # buflen
    inc x
    ld r3, (x) # bufpos

    # if (bufpos == buflen)
    sub r2, r3
    jnz _bgetc_nextchar
    #   _bslurp(bio):
    ld x, r254
    push x
    ld x, (_bgetc_bio)
    push x
    call (__bslurp)
    pop x
    ld r254, x

    _bgetc_nextchar:
    # if (buflen == 0) return EOF;
    ld x, (_bgetc_bio)
    inc x
    ld r2, (x) # buflen
    test r2
    jnz _bgetc_not_eof
    ld r0, (_EOF)
    ret

    _bgetc_not_eof:
    inc x
    ld r3, (x) # bufpos

    # ch = *(bio+4+bufpos)
    ld x, (_bgetc_bio)
    add x, 4
    add x, r3
    ld r0, (x)

    # bufpos++
    inc r3
    ld x, (_bgetc_bio)
    add x, 2
    ld (x), r3

    ret

    _bgetc_bio: .word 0
};

#var bputc = func(bio, ch) {
#    var bufpos = bio[2];
#    *(bio+4+bufpos) = ch;
#    *(bio+2) = bufpos+1;
#    if (bufpos == BIO_BUFSZ) bflush(bio);
#};
#
# usage: bputc(bio, ch)
var bputc = asm {
    pop x
    ld r2, x # ch
    pop x
    ld r1, x # bio

    ld r3, r1
    add r3, 2 # r3 is bio+2, i.e. pointer to bufpos
    # dereference bufpos pointer into r5
    ld x, (r3)
    ld r5, x

    ld r4, r1
    add r4, 4
    add r4, r5
    # r4 = address for next char (bio+4+bufpos)

    # write char to buffer
    ld x, r2
    ld (r4), x

    # increment bufpos and store back to bio object
    inc r5
    ld x, r5
    ld (r3), x

    # if (bufpos == BIO_BUFSZ) bflush(bio)
    ld x, (_BIO_BUFSZ)
    sub r5, x
    jz bputc_bflush
    ret

    bputc_bflush:
        # tail call bflush(bio)
        ld x, r1
        push x
        jmp (_bflush)
};

var bputs = func(bio, str) {
    while (*str)
        bputc(bio, *(str++));
};

var bprintf_bio;
var bprintf = func(bio, fmt, args) {
    bprintf_bio = bio;
    return xprintf(fmt, args, func(ch) {
        bputc(bprintf_bio, ch);
    });
};
