
kernel:     file format elf32-i386


Disassembly of section .text:

80100000 <multiboot_header>:
80100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
80100006:	00 00                	add    %al,(%eax)
80100008:	fe 4f 52             	decb   0x52(%edi)
8010000b:	e4 0f                	in     $0xf,%al

8010000c <entry>:

# Entering xv6 on boot processor, with paging off.
.globl entry
entry:
  # Turn on page size extension for 4Mbyte pages
  movl    %cr4, %eax
8010000c:	0f 20 e0             	mov    %cr4,%eax
  orl     $(CR4_PSE), %eax
8010000f:	83 c8 10             	or     $0x10,%eax
  movl    %eax, %cr4
80100012:	0f 22 e0             	mov    %eax,%cr4
  # Set page directory
  movl    $(V2P_WO(entrypgdir)), %eax
80100015:	b8 00 a0 10 00       	mov    $0x10a000,%eax
  movl    %eax, %cr3
8010001a:	0f 22 d8             	mov    %eax,%cr3
  # Turn on paging.
  movl    %cr0, %eax
8010001d:	0f 20 c0             	mov    %cr0,%eax
  orl     $(CR0_PG|CR0_WP), %eax
80100020:	0d 00 00 01 80       	or     $0x80010000,%eax
  movl    %eax, %cr0
80100025:	0f 22 c0             	mov    %eax,%cr0

  # Set up the stack pointer.
  movl $(stack + KSTACKSIZE), %esp
80100028:	bc 50 c6 10 80       	mov    $0x8010c650,%esp

  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  mov $main, %eax
8010002d:	b8 ff 33 10 80       	mov    $0x801033ff,%eax
  jmp *%eax
80100032:	ff e0                	jmp    *%eax

80100034 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
80100034:	55                   	push   %ebp
80100035:	89 e5                	mov    %esp,%ebp
80100037:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  initlock(&bcache.lock, "bcache");
8010003a:	c7 44 24 04 7c 80 10 	movl   $0x8010807c,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
80100049:	e8 54 4a 00 00       	call   80104aa2 <initlock>

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
8010004e:	c7 05 90 db 10 80 84 	movl   $0x8010db84,0x8010db90
80100055:	db 10 80 
  bcache.head.next = &bcache.head;
80100058:	c7 05 94 db 10 80 84 	movl   $0x8010db84,0x8010db94
8010005f:	db 10 80 
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
80100062:	c7 45 f4 94 c6 10 80 	movl   $0x8010c694,-0xc(%ebp)
80100069:	eb 3a                	jmp    801000a5 <binit+0x71>
    b->next = bcache.head.next;
8010006b:	8b 15 94 db 10 80    	mov    0x8010db94,%edx
80100071:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100074:	89 50 10             	mov    %edx,0x10(%eax)
    b->prev = &bcache.head;
80100077:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010007a:	c7 40 0c 84 db 10 80 	movl   $0x8010db84,0xc(%eax)
    b->dev = -1;
80100081:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100084:	c7 40 04 ff ff ff ff 	movl   $0xffffffff,0x4(%eax)
    bcache.head.next->prev = b;
8010008b:	a1 94 db 10 80       	mov    0x8010db94,%eax
80100090:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100093:	89 50 0c             	mov    %edx,0xc(%eax)
    bcache.head.next = b;
80100096:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100099:	a3 94 db 10 80       	mov    %eax,0x8010db94

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
  bcache.head.next = &bcache.head;
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
8010009e:	81 45 f4 18 02 00 00 	addl   $0x218,-0xc(%ebp)
801000a5:	81 7d f4 84 db 10 80 	cmpl   $0x8010db84,-0xc(%ebp)
801000ac:	72 bd                	jb     8010006b <binit+0x37>
    b->prev = &bcache.head;
    b->dev = -1;
    bcache.head.next->prev = b;
    bcache.head.next = b;
  }
}
801000ae:	c9                   	leave  
801000af:	c3                   	ret    

801000b0 <bget>:
// Look through buffer cache for sector on device dev.
// If not found, allocate fresh block.
// In either case, return B_BUSY buffer.
static struct buf*
bget(uint dev, uint sector)
{
801000b0:	55                   	push   %ebp
801000b1:	89 e5                	mov    %esp,%ebp
801000b3:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  acquire(&bcache.lock);
801000b6:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
801000bd:	e8 01 4a 00 00       	call   80104ac3 <acquire>

 loop:
  // Is the sector already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
801000c2:	a1 94 db 10 80       	mov    0x8010db94,%eax
801000c7:	89 45 f4             	mov    %eax,-0xc(%ebp)
801000ca:	eb 63                	jmp    8010012f <bget+0x7f>
    if(b->dev == dev && b->sector == sector){
801000cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000cf:	8b 40 04             	mov    0x4(%eax),%eax
801000d2:	3b 45 08             	cmp    0x8(%ebp),%eax
801000d5:	75 4f                	jne    80100126 <bget+0x76>
801000d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000da:	8b 40 08             	mov    0x8(%eax),%eax
801000dd:	3b 45 0c             	cmp    0xc(%ebp),%eax
801000e0:	75 44                	jne    80100126 <bget+0x76>
      if(!(b->flags & B_BUSY)){
801000e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000e5:	8b 00                	mov    (%eax),%eax
801000e7:	83 e0 01             	and    $0x1,%eax
801000ea:	85 c0                	test   %eax,%eax
801000ec:	75 23                	jne    80100111 <bget+0x61>
        b->flags |= B_BUSY;
801000ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000f1:	8b 00                	mov    (%eax),%eax
801000f3:	89 c2                	mov    %eax,%edx
801000f5:	83 ca 01             	or     $0x1,%edx
801000f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000fb:	89 10                	mov    %edx,(%eax)
        release(&bcache.lock);
801000fd:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
80100104:	e8 1c 4a 00 00       	call   80104b25 <release>
        return b;
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	e9 93 00 00 00       	jmp    801001a4 <bget+0xf4>
      }
      sleep(b, &bcache.lock);
80100111:	c7 44 24 04 60 c6 10 	movl   $0x8010c660,0x4(%esp)
80100118:	80 
80100119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011c:	89 04 24             	mov    %eax,(%esp)
8010011f:	e8 c3 46 00 00       	call   801047e7 <sleep>
      goto loop;
80100124:	eb 9c                	jmp    801000c2 <bget+0x12>

  acquire(&bcache.lock);

 loop:
  // Is the sector already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
80100126:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100129:	8b 40 10             	mov    0x10(%eax),%eax
8010012c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010012f:	81 7d f4 84 db 10 80 	cmpl   $0x8010db84,-0xc(%ebp)
80100136:	75 94                	jne    801000cc <bget+0x1c>
      goto loop;
    }
  }

  // Not cached; recycle some non-busy and clean buffer.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100138:	a1 90 db 10 80       	mov    0x8010db90,%eax
8010013d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100140:	eb 4d                	jmp    8010018f <bget+0xdf>
    if((b->flags & B_BUSY) == 0 && (b->flags & B_DIRTY) == 0){
80100142:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100145:	8b 00                	mov    (%eax),%eax
80100147:	83 e0 01             	and    $0x1,%eax
8010014a:	85 c0                	test   %eax,%eax
8010014c:	75 38                	jne    80100186 <bget+0xd6>
8010014e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100151:	8b 00                	mov    (%eax),%eax
80100153:	83 e0 04             	and    $0x4,%eax
80100156:	85 c0                	test   %eax,%eax
80100158:	75 2c                	jne    80100186 <bget+0xd6>
      b->dev = dev;
8010015a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010015d:	8b 55 08             	mov    0x8(%ebp),%edx
80100160:	89 50 04             	mov    %edx,0x4(%eax)
      b->sector = sector;
80100163:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100166:	8b 55 0c             	mov    0xc(%ebp),%edx
80100169:	89 50 08             	mov    %edx,0x8(%eax)
      b->flags = B_BUSY;
8010016c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010016f:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
      release(&bcache.lock);
80100175:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
8010017c:	e8 a4 49 00 00       	call   80104b25 <release>
      return b;
80100181:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100184:	eb 1e                	jmp    801001a4 <bget+0xf4>
      goto loop;
    }
  }

  // Not cached; recycle some non-busy and clean buffer.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100186:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100189:	8b 40 0c             	mov    0xc(%eax),%eax
8010018c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010018f:	81 7d f4 84 db 10 80 	cmpl   $0x8010db84,-0xc(%ebp)
80100196:	75 aa                	jne    80100142 <bget+0x92>
      b->flags = B_BUSY;
      release(&bcache.lock);
      return b;
    }
  }
  panic("bget: no buffers");
80100198:	c7 04 24 83 80 10 80 	movl   $0x80108083,(%esp)
8010019f:	e8 99 03 00 00       	call   8010053d <panic>
}
801001a4:	c9                   	leave  
801001a5:	c3                   	ret    

801001a6 <bread>:

// Return a B_BUSY buf with the contents of the indicated disk sector.
struct buf*
bread(uint dev, uint sector)
{
801001a6:	55                   	push   %ebp
801001a7:	89 e5                	mov    %esp,%ebp
801001a9:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  b = bget(dev, sector);
801001ac:	8b 45 0c             	mov    0xc(%ebp),%eax
801001af:	89 44 24 04          	mov    %eax,0x4(%esp)
801001b3:	8b 45 08             	mov    0x8(%ebp),%eax
801001b6:	89 04 24             	mov    %eax,(%esp)
801001b9:	e8 f2 fe ff ff       	call   801000b0 <bget>
801001be:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(!(b->flags & B_VALID))
801001c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801001c4:	8b 00                	mov    (%eax),%eax
801001c6:	83 e0 02             	and    $0x2,%eax
801001c9:	85 c0                	test   %eax,%eax
801001cb:	75 0b                	jne    801001d8 <bread+0x32>
    iderw(b);
801001cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801001d0:	89 04 24             	mov    %eax,(%esp)
801001d3:	e8 d4 25 00 00       	call   801027ac <iderw>
  return b;
801001d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801001db:	c9                   	leave  
801001dc:	c3                   	ret    

801001dd <bwrite>:

// Write b's contents to disk.  Must be B_BUSY.
void
bwrite(struct buf *b)
{
801001dd:	55                   	push   %ebp
801001de:	89 e5                	mov    %esp,%ebp
801001e0:	83 ec 18             	sub    $0x18,%esp
  if((b->flags & B_BUSY) == 0)
801001e3:	8b 45 08             	mov    0x8(%ebp),%eax
801001e6:	8b 00                	mov    (%eax),%eax
801001e8:	83 e0 01             	and    $0x1,%eax
801001eb:	85 c0                	test   %eax,%eax
801001ed:	75 0c                	jne    801001fb <bwrite+0x1e>
    panic("bwrite");
801001ef:	c7 04 24 94 80 10 80 	movl   $0x80108094,(%esp)
801001f6:	e8 42 03 00 00       	call   8010053d <panic>
  b->flags |= B_DIRTY;
801001fb:	8b 45 08             	mov    0x8(%ebp),%eax
801001fe:	8b 00                	mov    (%eax),%eax
80100200:	89 c2                	mov    %eax,%edx
80100202:	83 ca 04             	or     $0x4,%edx
80100205:	8b 45 08             	mov    0x8(%ebp),%eax
80100208:	89 10                	mov    %edx,(%eax)
  iderw(b);
8010020a:	8b 45 08             	mov    0x8(%ebp),%eax
8010020d:	89 04 24             	mov    %eax,(%esp)
80100210:	e8 97 25 00 00       	call   801027ac <iderw>
}
80100215:	c9                   	leave  
80100216:	c3                   	ret    

80100217 <brelse>:

// Release a B_BUSY buffer.
// Move to the head of the MRU list.
void
brelse(struct buf *b)
{
80100217:	55                   	push   %ebp
80100218:	89 e5                	mov    %esp,%ebp
8010021a:	83 ec 18             	sub    $0x18,%esp
  if((b->flags & B_BUSY) == 0)
8010021d:	8b 45 08             	mov    0x8(%ebp),%eax
80100220:	8b 00                	mov    (%eax),%eax
80100222:	83 e0 01             	and    $0x1,%eax
80100225:	85 c0                	test   %eax,%eax
80100227:	75 0c                	jne    80100235 <brelse+0x1e>
    panic("brelse");
80100229:	c7 04 24 9b 80 10 80 	movl   $0x8010809b,(%esp)
80100230:	e8 08 03 00 00       	call   8010053d <panic>

  acquire(&bcache.lock);
80100235:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
8010023c:	e8 82 48 00 00       	call   80104ac3 <acquire>

  b->next->prev = b->prev;
80100241:	8b 45 08             	mov    0x8(%ebp),%eax
80100244:	8b 40 10             	mov    0x10(%eax),%eax
80100247:	8b 55 08             	mov    0x8(%ebp),%edx
8010024a:	8b 52 0c             	mov    0xc(%edx),%edx
8010024d:	89 50 0c             	mov    %edx,0xc(%eax)
  b->prev->next = b->next;
80100250:	8b 45 08             	mov    0x8(%ebp),%eax
80100253:	8b 40 0c             	mov    0xc(%eax),%eax
80100256:	8b 55 08             	mov    0x8(%ebp),%edx
80100259:	8b 52 10             	mov    0x10(%edx),%edx
8010025c:	89 50 10             	mov    %edx,0x10(%eax)
  b->next = bcache.head.next;
8010025f:	8b 15 94 db 10 80    	mov    0x8010db94,%edx
80100265:	8b 45 08             	mov    0x8(%ebp),%eax
80100268:	89 50 10             	mov    %edx,0x10(%eax)
  b->prev = &bcache.head;
8010026b:	8b 45 08             	mov    0x8(%ebp),%eax
8010026e:	c7 40 0c 84 db 10 80 	movl   $0x8010db84,0xc(%eax)
  bcache.head.next->prev = b;
80100275:	a1 94 db 10 80       	mov    0x8010db94,%eax
8010027a:	8b 55 08             	mov    0x8(%ebp),%edx
8010027d:	89 50 0c             	mov    %edx,0xc(%eax)
  bcache.head.next = b;
80100280:	8b 45 08             	mov    0x8(%ebp),%eax
80100283:	a3 94 db 10 80       	mov    %eax,0x8010db94

  b->flags &= ~B_BUSY;
80100288:	8b 45 08             	mov    0x8(%ebp),%eax
8010028b:	8b 00                	mov    (%eax),%eax
8010028d:	89 c2                	mov    %eax,%edx
8010028f:	83 e2 fe             	and    $0xfffffffe,%edx
80100292:	8b 45 08             	mov    0x8(%ebp),%eax
80100295:	89 10                	mov    %edx,(%eax)
  wakeup(b);
80100297:	8b 45 08             	mov    0x8(%ebp),%eax
8010029a:	89 04 24             	mov    %eax,(%esp)
8010029d:	e8 1e 46 00 00       	call   801048c0 <wakeup>

  release(&bcache.lock);
801002a2:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
801002a9:	e8 77 48 00 00       	call   80104b25 <release>
}
801002ae:	c9                   	leave  
801002af:	c3                   	ret    

801002b0 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801002b0:	55                   	push   %ebp
801002b1:	89 e5                	mov    %esp,%ebp
801002b3:	53                   	push   %ebx
801002b4:	83 ec 14             	sub    $0x14,%esp
801002b7:	8b 45 08             	mov    0x8(%ebp),%eax
801002ba:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801002be:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
801002c2:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
801002c6:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
801002ca:	ec                   	in     (%dx),%al
801002cb:	89 c3                	mov    %eax,%ebx
801002cd:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
801002d0:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
801002d4:	83 c4 14             	add    $0x14,%esp
801002d7:	5b                   	pop    %ebx
801002d8:	5d                   	pop    %ebp
801002d9:	c3                   	ret    

801002da <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801002da:	55                   	push   %ebp
801002db:	89 e5                	mov    %esp,%ebp
801002dd:	83 ec 08             	sub    $0x8,%esp
801002e0:	8b 55 08             	mov    0x8(%ebp),%edx
801002e3:	8b 45 0c             	mov    0xc(%ebp),%eax
801002e6:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801002ea:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801002ed:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801002f1:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801002f5:	ee                   	out    %al,(%dx)
}
801002f6:	c9                   	leave  
801002f7:	c3                   	ret    

801002f8 <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
801002f8:	55                   	push   %ebp
801002f9:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
801002fb:	fa                   	cli    
}
801002fc:	5d                   	pop    %ebp
801002fd:	c3                   	ret    

801002fe <printint>:
  int locking;
} cons;

static void
printint(int xx, int base, int sign)
{
801002fe:	55                   	push   %ebp
801002ff:	89 e5                	mov    %esp,%ebp
80100301:	83 ec 48             	sub    $0x48,%esp
  static char digits[] = "0123456789abcdef";
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
80100304:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80100308:	74 19                	je     80100323 <printint+0x25>
8010030a:	8b 45 08             	mov    0x8(%ebp),%eax
8010030d:	c1 e8 1f             	shr    $0x1f,%eax
80100310:	89 45 10             	mov    %eax,0x10(%ebp)
80100313:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80100317:	74 0a                	je     80100323 <printint+0x25>
    x = -xx;
80100319:	8b 45 08             	mov    0x8(%ebp),%eax
8010031c:	f7 d8                	neg    %eax
8010031e:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100321:	eb 06                	jmp    80100329 <printint+0x2b>
  else
    x = xx;
80100323:	8b 45 08             	mov    0x8(%ebp),%eax
80100326:	89 45 f0             	mov    %eax,-0x10(%ebp)

  i = 0;
80100329:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  do{
    buf[i++] = digits[x % base];
80100330:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80100333:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100336:	ba 00 00 00 00       	mov    $0x0,%edx
8010033b:	f7 f1                	div    %ecx
8010033d:	89 d0                	mov    %edx,%eax
8010033f:	0f b6 90 04 90 10 80 	movzbl -0x7fef6ffc(%eax),%edx
80100346:	8d 45 e0             	lea    -0x20(%ebp),%eax
80100349:	03 45 f4             	add    -0xc(%ebp),%eax
8010034c:	88 10                	mov    %dl,(%eax)
8010034e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  }while((x /= base) != 0);
80100352:	8b 55 0c             	mov    0xc(%ebp),%edx
80100355:	89 55 d4             	mov    %edx,-0x2c(%ebp)
80100358:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010035b:	ba 00 00 00 00       	mov    $0x0,%edx
80100360:	f7 75 d4             	divl   -0x2c(%ebp)
80100363:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100366:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010036a:	75 c4                	jne    80100330 <printint+0x32>

  if(sign)
8010036c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80100370:	74 23                	je     80100395 <printint+0x97>
    buf[i++] = '-';
80100372:	8d 45 e0             	lea    -0x20(%ebp),%eax
80100375:	03 45 f4             	add    -0xc(%ebp),%eax
80100378:	c6 00 2d             	movb   $0x2d,(%eax)
8010037b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)

  while(--i >= 0)
8010037f:	eb 14                	jmp    80100395 <printint+0x97>
    consputc(buf[i]);
80100381:	8d 45 e0             	lea    -0x20(%ebp),%eax
80100384:	03 45 f4             	add    -0xc(%ebp),%eax
80100387:	0f b6 00             	movzbl (%eax),%eax
8010038a:	0f be c0             	movsbl %al,%eax
8010038d:	89 04 24             	mov    %eax,(%esp)
80100390:	e8 bb 03 00 00       	call   80100750 <consputc>
  }while((x /= base) != 0);

  if(sign)
    buf[i++] = '-';

  while(--i >= 0)
80100395:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
80100399:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010039d:	79 e2                	jns    80100381 <printint+0x83>
    consputc(buf[i]);
}
8010039f:	c9                   	leave  
801003a0:	c3                   	ret    

801003a1 <cprintf>:
//PAGEBREAK: 50

// Print to the console. only understands %d, %x, %p, %s.
void
cprintf(char *fmt, ...)
{
801003a1:	55                   	push   %ebp
801003a2:	89 e5                	mov    %esp,%ebp
801003a4:	83 ec 38             	sub    $0x38,%esp
  int i, c, locking;
  uint *argp;
  char *s;

  locking = cons.locking;
801003a7:	a1 f4 b5 10 80       	mov    0x8010b5f4,%eax
801003ac:	89 45 e8             	mov    %eax,-0x18(%ebp)
  if(locking)
801003af:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801003b3:	74 0c                	je     801003c1 <cprintf+0x20>
    acquire(&cons.lock);
801003b5:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
801003bc:	e8 02 47 00 00       	call   80104ac3 <acquire>

  if (fmt == 0)
801003c1:	8b 45 08             	mov    0x8(%ebp),%eax
801003c4:	85 c0                	test   %eax,%eax
801003c6:	75 0c                	jne    801003d4 <cprintf+0x33>
    panic("null fmt");
801003c8:	c7 04 24 a2 80 10 80 	movl   $0x801080a2,(%esp)
801003cf:	e8 69 01 00 00       	call   8010053d <panic>

  argp = (uint*)(void*)(&fmt + 1);
801003d4:	8d 45 0c             	lea    0xc(%ebp),%eax
801003d7:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
801003da:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801003e1:	e9 20 01 00 00       	jmp    80100506 <cprintf+0x165>
    if(c != '%'){
801003e6:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
801003ea:	74 10                	je     801003fc <cprintf+0x5b>
      consputc(c);
801003ec:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801003ef:	89 04 24             	mov    %eax,(%esp)
801003f2:	e8 59 03 00 00       	call   80100750 <consputc>
      continue;
801003f7:	e9 06 01 00 00       	jmp    80100502 <cprintf+0x161>
    }
    c = fmt[++i] & 0xff;
801003fc:	8b 55 08             	mov    0x8(%ebp),%edx
801003ff:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100403:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100406:	01 d0                	add    %edx,%eax
80100408:	0f b6 00             	movzbl (%eax),%eax
8010040b:	0f be c0             	movsbl %al,%eax
8010040e:	25 ff 00 00 00       	and    $0xff,%eax
80100413:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(c == 0)
80100416:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
8010041a:	0f 84 08 01 00 00    	je     80100528 <cprintf+0x187>
      break;
    switch(c){
80100420:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100423:	83 f8 70             	cmp    $0x70,%eax
80100426:	74 4d                	je     80100475 <cprintf+0xd4>
80100428:	83 f8 70             	cmp    $0x70,%eax
8010042b:	7f 13                	jg     80100440 <cprintf+0x9f>
8010042d:	83 f8 25             	cmp    $0x25,%eax
80100430:	0f 84 a6 00 00 00    	je     801004dc <cprintf+0x13b>
80100436:	83 f8 64             	cmp    $0x64,%eax
80100439:	74 14                	je     8010044f <cprintf+0xae>
8010043b:	e9 aa 00 00 00       	jmp    801004ea <cprintf+0x149>
80100440:	83 f8 73             	cmp    $0x73,%eax
80100443:	74 53                	je     80100498 <cprintf+0xf7>
80100445:	83 f8 78             	cmp    $0x78,%eax
80100448:	74 2b                	je     80100475 <cprintf+0xd4>
8010044a:	e9 9b 00 00 00       	jmp    801004ea <cprintf+0x149>
    case 'd':
      printint(*argp++, 10, 1);
8010044f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100452:	8b 00                	mov    (%eax),%eax
80100454:	83 45 f0 04          	addl   $0x4,-0x10(%ebp)
80100458:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
8010045f:	00 
80100460:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80100467:	00 
80100468:	89 04 24             	mov    %eax,(%esp)
8010046b:	e8 8e fe ff ff       	call   801002fe <printint>
      break;
80100470:	e9 8d 00 00 00       	jmp    80100502 <cprintf+0x161>
    case 'x':
    case 'p':
      printint(*argp++, 16, 0);
80100475:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100478:	8b 00                	mov    (%eax),%eax
8010047a:	83 45 f0 04          	addl   $0x4,-0x10(%ebp)
8010047e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80100485:	00 
80100486:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
8010048d:	00 
8010048e:	89 04 24             	mov    %eax,(%esp)
80100491:	e8 68 fe ff ff       	call   801002fe <printint>
      break;
80100496:	eb 6a                	jmp    80100502 <cprintf+0x161>
    case 's':
      if((s = (char*)*argp++) == 0)
80100498:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010049b:	8b 00                	mov    (%eax),%eax
8010049d:	89 45 ec             	mov    %eax,-0x14(%ebp)
801004a0:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801004a4:	0f 94 c0             	sete   %al
801004a7:	83 45 f0 04          	addl   $0x4,-0x10(%ebp)
801004ab:	84 c0                	test   %al,%al
801004ad:	74 20                	je     801004cf <cprintf+0x12e>
        s = "(null)";
801004af:	c7 45 ec ab 80 10 80 	movl   $0x801080ab,-0x14(%ebp)
      for(; *s; s++)
801004b6:	eb 17                	jmp    801004cf <cprintf+0x12e>
        consputc(*s);
801004b8:	8b 45 ec             	mov    -0x14(%ebp),%eax
801004bb:	0f b6 00             	movzbl (%eax),%eax
801004be:	0f be c0             	movsbl %al,%eax
801004c1:	89 04 24             	mov    %eax,(%esp)
801004c4:	e8 87 02 00 00       	call   80100750 <consputc>
      printint(*argp++, 16, 0);
      break;
    case 's':
      if((s = (char*)*argp++) == 0)
        s = "(null)";
      for(; *s; s++)
801004c9:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
801004cd:	eb 01                	jmp    801004d0 <cprintf+0x12f>
801004cf:	90                   	nop
801004d0:	8b 45 ec             	mov    -0x14(%ebp),%eax
801004d3:	0f b6 00             	movzbl (%eax),%eax
801004d6:	84 c0                	test   %al,%al
801004d8:	75 de                	jne    801004b8 <cprintf+0x117>
        consputc(*s);
      break;
801004da:	eb 26                	jmp    80100502 <cprintf+0x161>
    case '%':
      consputc('%');
801004dc:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
801004e3:	e8 68 02 00 00       	call   80100750 <consputc>
      break;
801004e8:	eb 18                	jmp    80100502 <cprintf+0x161>
    default:
      // Print unknown % sequence to draw attention.
      consputc('%');
801004ea:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
801004f1:	e8 5a 02 00 00       	call   80100750 <consputc>
      consputc(c);
801004f6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801004f9:	89 04 24             	mov    %eax,(%esp)
801004fc:	e8 4f 02 00 00       	call   80100750 <consputc>
      break;
80100501:	90                   	nop

  if (fmt == 0)
    panic("null fmt");

  argp = (uint*)(void*)(&fmt + 1);
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
80100502:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100506:	8b 55 08             	mov    0x8(%ebp),%edx
80100509:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010050c:	01 d0                	add    %edx,%eax
8010050e:	0f b6 00             	movzbl (%eax),%eax
80100511:	0f be c0             	movsbl %al,%eax
80100514:	25 ff 00 00 00       	and    $0xff,%eax
80100519:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010051c:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80100520:	0f 85 c0 fe ff ff    	jne    801003e6 <cprintf+0x45>
80100526:	eb 01                	jmp    80100529 <cprintf+0x188>
      consputc(c);
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
80100528:	90                   	nop
      consputc(c);
      break;
    }
  }

  if(locking)
80100529:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
8010052d:	74 0c                	je     8010053b <cprintf+0x19a>
    release(&cons.lock);
8010052f:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100536:	e8 ea 45 00 00       	call   80104b25 <release>
}
8010053b:	c9                   	leave  
8010053c:	c3                   	ret    

8010053d <panic>:

void
panic(char *s)
{
8010053d:	55                   	push   %ebp
8010053e:	89 e5                	mov    %esp,%ebp
80100540:	83 ec 48             	sub    $0x48,%esp
  int i;
  uint pcs[10];
  
  cli();
80100543:	e8 b0 fd ff ff       	call   801002f8 <cli>
  cons.locking = 0;
80100548:	c7 05 f4 b5 10 80 00 	movl   $0x0,0x8010b5f4
8010054f:	00 00 00 
  cprintf("cpu%d: panic: ", cpu->id);
80100552:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80100558:	0f b6 00             	movzbl (%eax),%eax
8010055b:	0f b6 c0             	movzbl %al,%eax
8010055e:	89 44 24 04          	mov    %eax,0x4(%esp)
80100562:	c7 04 24 b2 80 10 80 	movl   $0x801080b2,(%esp)
80100569:	e8 33 fe ff ff       	call   801003a1 <cprintf>
  cprintf(s);
8010056e:	8b 45 08             	mov    0x8(%ebp),%eax
80100571:	89 04 24             	mov    %eax,(%esp)
80100574:	e8 28 fe ff ff       	call   801003a1 <cprintf>
  cprintf("\n");
80100579:	c7 04 24 c1 80 10 80 	movl   $0x801080c1,(%esp)
80100580:	e8 1c fe ff ff       	call   801003a1 <cprintf>
  getcallerpcs(&s, pcs);
80100585:	8d 45 cc             	lea    -0x34(%ebp),%eax
80100588:	89 44 24 04          	mov    %eax,0x4(%esp)
8010058c:	8d 45 08             	lea    0x8(%ebp),%eax
8010058f:	89 04 24             	mov    %eax,(%esp)
80100592:	e8 dd 45 00 00       	call   80104b74 <getcallerpcs>
  for(i=0; i<10; i++)
80100597:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010059e:	eb 1b                	jmp    801005bb <panic+0x7e>
    cprintf(" %p", pcs[i]);
801005a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005a3:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005a7:	89 44 24 04          	mov    %eax,0x4(%esp)
801005ab:	c7 04 24 c3 80 10 80 	movl   $0x801080c3,(%esp)
801005b2:	e8 ea fd ff ff       	call   801003a1 <cprintf>
  cons.locking = 0;
  cprintf("cpu%d: panic: ", cpu->id);
  cprintf(s);
  cprintf("\n");
  getcallerpcs(&s, pcs);
  for(i=0; i<10; i++)
801005b7:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801005bb:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
801005bf:	7e df                	jle    801005a0 <panic+0x63>
    cprintf(" %p", pcs[i]);
  panicked = 1; // freeze other CPU
801005c1:	c7 05 a0 b5 10 80 01 	movl   $0x1,0x8010b5a0
801005c8:	00 00 00 
  for(;;)
    ;
801005cb:	eb fe                	jmp    801005cb <panic+0x8e>

801005cd <cgaputc>:
#define CRTPORT 0x3d4
static ushort *crt = (ushort*)P2V(0xb8000);  // CGA memory

static void
cgaputc(int c)
{
801005cd:	55                   	push   %ebp
801005ce:	89 e5                	mov    %esp,%ebp
801005d0:	83 ec 28             	sub    $0x28,%esp
  int pos;
  
  // Cursor position: col + 80*row.
  outb(CRTPORT, 14);
801005d3:	c7 44 24 04 0e 00 00 	movl   $0xe,0x4(%esp)
801005da:	00 
801005db:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
801005e2:	e8 f3 fc ff ff       	call   801002da <outb>
  pos = inb(CRTPORT+1) << 8;
801005e7:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
801005ee:	e8 bd fc ff ff       	call   801002b0 <inb>
801005f3:	0f b6 c0             	movzbl %al,%eax
801005f6:	c1 e0 08             	shl    $0x8,%eax
801005f9:	89 45 f4             	mov    %eax,-0xc(%ebp)
  outb(CRTPORT, 15);
801005fc:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80100603:	00 
80100604:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
8010060b:	e8 ca fc ff ff       	call   801002da <outb>
  pos |= inb(CRTPORT+1);
80100610:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
80100617:	e8 94 fc ff ff       	call   801002b0 <inb>
8010061c:	0f b6 c0             	movzbl %al,%eax
8010061f:	09 45 f4             	or     %eax,-0xc(%ebp)

  if(c == '\n')
80100622:	83 7d 08 0a          	cmpl   $0xa,0x8(%ebp)
80100626:	75 30                	jne    80100658 <cgaputc+0x8b>
    pos += 80 - pos%80;
80100628:	8b 4d f4             	mov    -0xc(%ebp),%ecx
8010062b:	ba 67 66 66 66       	mov    $0x66666667,%edx
80100630:	89 c8                	mov    %ecx,%eax
80100632:	f7 ea                	imul   %edx
80100634:	c1 fa 05             	sar    $0x5,%edx
80100637:	89 c8                	mov    %ecx,%eax
80100639:	c1 f8 1f             	sar    $0x1f,%eax
8010063c:	29 c2                	sub    %eax,%edx
8010063e:	89 d0                	mov    %edx,%eax
80100640:	c1 e0 02             	shl    $0x2,%eax
80100643:	01 d0                	add    %edx,%eax
80100645:	c1 e0 04             	shl    $0x4,%eax
80100648:	89 ca                	mov    %ecx,%edx
8010064a:	29 c2                	sub    %eax,%edx
8010064c:	b8 50 00 00 00       	mov    $0x50,%eax
80100651:	29 d0                	sub    %edx,%eax
80100653:	01 45 f4             	add    %eax,-0xc(%ebp)
80100656:	eb 32                	jmp    8010068a <cgaputc+0xbd>
  else if(c == BACKSPACE){
80100658:	81 7d 08 00 01 00 00 	cmpl   $0x100,0x8(%ebp)
8010065f:	75 0c                	jne    8010066d <cgaputc+0xa0>
    if(pos > 0) --pos;
80100661:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100665:	7e 23                	jle    8010068a <cgaputc+0xbd>
80100667:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
8010066b:	eb 1d                	jmp    8010068a <cgaputc+0xbd>
  } else
    crt[pos++] = (c&0xff) | 0x0700;  // black on white
8010066d:	a1 00 90 10 80       	mov    0x80109000,%eax
80100672:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100675:	01 d2                	add    %edx,%edx
80100677:	01 c2                	add    %eax,%edx
80100679:	8b 45 08             	mov    0x8(%ebp),%eax
8010067c:	66 25 ff 00          	and    $0xff,%ax
80100680:	80 cc 07             	or     $0x7,%ah
80100683:	66 89 02             	mov    %ax,(%edx)
80100686:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  
  if((pos/80) >= 24){  // Scroll up.
8010068a:	81 7d f4 7f 07 00 00 	cmpl   $0x77f,-0xc(%ebp)
80100691:	7e 53                	jle    801006e6 <cgaputc+0x119>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
80100693:	a1 00 90 10 80       	mov    0x80109000,%eax
80100698:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
8010069e:	a1 00 90 10 80       	mov    0x80109000,%eax
801006a3:	c7 44 24 08 60 0e 00 	movl   $0xe60,0x8(%esp)
801006aa:	00 
801006ab:	89 54 24 04          	mov    %edx,0x4(%esp)
801006af:	89 04 24             	mov    %eax,(%esp)
801006b2:	e8 2e 47 00 00       	call   80104de5 <memmove>
    pos -= 80;
801006b7:	83 6d f4 50          	subl   $0x50,-0xc(%ebp)
    memset(crt+pos, 0, sizeof(crt[0])*(24*80 - pos));
801006bb:	b8 80 07 00 00       	mov    $0x780,%eax
801006c0:	2b 45 f4             	sub    -0xc(%ebp),%eax
801006c3:	01 c0                	add    %eax,%eax
801006c5:	8b 15 00 90 10 80    	mov    0x80109000,%edx
801006cb:	8b 4d f4             	mov    -0xc(%ebp),%ecx
801006ce:	01 c9                	add    %ecx,%ecx
801006d0:	01 ca                	add    %ecx,%edx
801006d2:	89 44 24 08          	mov    %eax,0x8(%esp)
801006d6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801006dd:	00 
801006de:	89 14 24             	mov    %edx,(%esp)
801006e1:	e8 2c 46 00 00       	call   80104d12 <memset>
  }
  
  outb(CRTPORT, 14);
801006e6:	c7 44 24 04 0e 00 00 	movl   $0xe,0x4(%esp)
801006ed:	00 
801006ee:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
801006f5:	e8 e0 fb ff ff       	call   801002da <outb>
  outb(CRTPORT+1, pos>>8);
801006fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801006fd:	c1 f8 08             	sar    $0x8,%eax
80100700:	0f b6 c0             	movzbl %al,%eax
80100703:	89 44 24 04          	mov    %eax,0x4(%esp)
80100707:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
8010070e:	e8 c7 fb ff ff       	call   801002da <outb>
  outb(CRTPORT, 15);
80100713:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
8010071a:	00 
8010071b:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
80100722:	e8 b3 fb ff ff       	call   801002da <outb>
  outb(CRTPORT+1, pos);
80100727:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010072a:	0f b6 c0             	movzbl %al,%eax
8010072d:	89 44 24 04          	mov    %eax,0x4(%esp)
80100731:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
80100738:	e8 9d fb ff ff       	call   801002da <outb>
  crt[pos] = ' ' | 0x0700;
8010073d:	a1 00 90 10 80       	mov    0x80109000,%eax
80100742:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100745:	01 d2                	add    %edx,%edx
80100747:	01 d0                	add    %edx,%eax
80100749:	66 c7 00 20 07       	movw   $0x720,(%eax)
}
8010074e:	c9                   	leave  
8010074f:	c3                   	ret    

80100750 <consputc>:

void
consputc(int c)
{
80100750:	55                   	push   %ebp
80100751:	89 e5                	mov    %esp,%ebp
80100753:	83 ec 18             	sub    $0x18,%esp
  if(panicked){
80100756:	a1 a0 b5 10 80       	mov    0x8010b5a0,%eax
8010075b:	85 c0                	test   %eax,%eax
8010075d:	74 07                	je     80100766 <consputc+0x16>
    cli();
8010075f:	e8 94 fb ff ff       	call   801002f8 <cli>
    for(;;)
      ;
80100764:	eb fe                	jmp    80100764 <consputc+0x14>
  }

  if(c == BACKSPACE){
80100766:	81 7d 08 00 01 00 00 	cmpl   $0x100,0x8(%ebp)
8010076d:	75 26                	jne    80100795 <consputc+0x45>
    uartputc('\b'); uartputc(' '); uartputc('\b');
8010076f:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100776:	e8 52 5f 00 00       	call   801066cd <uartputc>
8010077b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80100782:	e8 46 5f 00 00       	call   801066cd <uartputc>
80100787:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
8010078e:	e8 3a 5f 00 00       	call   801066cd <uartputc>
80100793:	eb 0b                	jmp    801007a0 <consputc+0x50>
  } else
    uartputc(c);
80100795:	8b 45 08             	mov    0x8(%ebp),%eax
80100798:	89 04 24             	mov    %eax,(%esp)
8010079b:	e8 2d 5f 00 00       	call   801066cd <uartputc>
  cgaputc(c);
801007a0:	8b 45 08             	mov    0x8(%ebp),%eax
801007a3:	89 04 24             	mov    %eax,(%esp)
801007a6:	e8 22 fe ff ff       	call   801005cd <cgaputc>
}
801007ab:	c9                   	leave  
801007ac:	c3                   	ret    

801007ad <consoleintr>:

#define C(x)  ((x)-'@')  // Control-x

void
consoleintr(int (*getc)(void))
{
801007ad:	55                   	push   %ebp
801007ae:	89 e5                	mov    %esp,%ebp
801007b0:	83 ec 28             	sub    $0x28,%esp
  int c;

  acquire(&input.lock);
801007b3:	c7 04 24 a0 dd 10 80 	movl   $0x8010dda0,(%esp)
801007ba:	e8 04 43 00 00       	call   80104ac3 <acquire>
  while((c = getc()) >= 0){
801007bf:	e9 41 01 00 00       	jmp    80100905 <consoleintr+0x158>
    switch(c){
801007c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801007c7:	83 f8 10             	cmp    $0x10,%eax
801007ca:	74 1e                	je     801007ea <consoleintr+0x3d>
801007cc:	83 f8 10             	cmp    $0x10,%eax
801007cf:	7f 0a                	jg     801007db <consoleintr+0x2e>
801007d1:	83 f8 08             	cmp    $0x8,%eax
801007d4:	74 68                	je     8010083e <consoleintr+0x91>
801007d6:	e9 94 00 00 00       	jmp    8010086f <consoleintr+0xc2>
801007db:	83 f8 15             	cmp    $0x15,%eax
801007de:	74 2f                	je     8010080f <consoleintr+0x62>
801007e0:	83 f8 7f             	cmp    $0x7f,%eax
801007e3:	74 59                	je     8010083e <consoleintr+0x91>
801007e5:	e9 85 00 00 00       	jmp    8010086f <consoleintr+0xc2>
    case C('P'):  // Process listing.
      procdump();
801007ea:	e8 74 41 00 00       	call   80104963 <procdump>
      break;
801007ef:	e9 11 01 00 00       	jmp    80100905 <consoleintr+0x158>
    case C('U'):  // Kill line.
      while(input.e != input.w &&
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
801007f4:	a1 5c de 10 80       	mov    0x8010de5c,%eax
801007f9:	83 e8 01             	sub    $0x1,%eax
801007fc:	a3 5c de 10 80       	mov    %eax,0x8010de5c
        consputc(BACKSPACE);
80100801:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
80100808:	e8 43 ff ff ff       	call   80100750 <consputc>
8010080d:	eb 01                	jmp    80100810 <consoleintr+0x63>
    switch(c){
    case C('P'):  // Process listing.
      procdump();
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
8010080f:	90                   	nop
80100810:	8b 15 5c de 10 80    	mov    0x8010de5c,%edx
80100816:	a1 58 de 10 80       	mov    0x8010de58,%eax
8010081b:	39 c2                	cmp    %eax,%edx
8010081d:	0f 84 db 00 00 00    	je     801008fe <consoleintr+0x151>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
80100823:	a1 5c de 10 80       	mov    0x8010de5c,%eax
80100828:	83 e8 01             	sub    $0x1,%eax
8010082b:	83 e0 7f             	and    $0x7f,%eax
8010082e:	0f b6 80 d4 dd 10 80 	movzbl -0x7fef222c(%eax),%eax
    switch(c){
    case C('P'):  // Process listing.
      procdump();
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
80100835:	3c 0a                	cmp    $0xa,%al
80100837:	75 bb                	jne    801007f4 <consoleintr+0x47>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
        consputc(BACKSPACE);
      }
      break;
80100839:	e9 c0 00 00 00       	jmp    801008fe <consoleintr+0x151>
    case C('H'): case '\x7f':  // Backspace
      if(input.e != input.w){
8010083e:	8b 15 5c de 10 80    	mov    0x8010de5c,%edx
80100844:	a1 58 de 10 80       	mov    0x8010de58,%eax
80100849:	39 c2                	cmp    %eax,%edx
8010084b:	0f 84 b0 00 00 00    	je     80100901 <consoleintr+0x154>
        input.e--;
80100851:	a1 5c de 10 80       	mov    0x8010de5c,%eax
80100856:	83 e8 01             	sub    $0x1,%eax
80100859:	a3 5c de 10 80       	mov    %eax,0x8010de5c
        consputc(BACKSPACE);
8010085e:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
80100865:	e8 e6 fe ff ff       	call   80100750 <consputc>
      }
      break;
8010086a:	e9 92 00 00 00       	jmp    80100901 <consoleintr+0x154>
    default:
      if(c != 0 && input.e-input.r < INPUT_BUF){
8010086f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100873:	0f 84 8b 00 00 00    	je     80100904 <consoleintr+0x157>
80100879:	8b 15 5c de 10 80    	mov    0x8010de5c,%edx
8010087f:	a1 54 de 10 80       	mov    0x8010de54,%eax
80100884:	89 d1                	mov    %edx,%ecx
80100886:	29 c1                	sub    %eax,%ecx
80100888:	89 c8                	mov    %ecx,%eax
8010088a:	83 f8 7f             	cmp    $0x7f,%eax
8010088d:	77 75                	ja     80100904 <consoleintr+0x157>
        c = (c == '\r') ? '\n' : c;
8010088f:	83 7d f4 0d          	cmpl   $0xd,-0xc(%ebp)
80100893:	74 05                	je     8010089a <consoleintr+0xed>
80100895:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100898:	eb 05                	jmp    8010089f <consoleintr+0xf2>
8010089a:	b8 0a 00 00 00       	mov    $0xa,%eax
8010089f:	89 45 f4             	mov    %eax,-0xc(%ebp)
        input.buf[input.e++ % INPUT_BUF] = c;
801008a2:	a1 5c de 10 80       	mov    0x8010de5c,%eax
801008a7:	89 c1                	mov    %eax,%ecx
801008a9:	83 e1 7f             	and    $0x7f,%ecx
801008ac:	8b 55 f4             	mov    -0xc(%ebp),%edx
801008af:	88 91 d4 dd 10 80    	mov    %dl,-0x7fef222c(%ecx)
801008b5:	83 c0 01             	add    $0x1,%eax
801008b8:	a3 5c de 10 80       	mov    %eax,0x8010de5c
        consputc(c);
801008bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801008c0:	89 04 24             	mov    %eax,(%esp)
801008c3:	e8 88 fe ff ff       	call   80100750 <consputc>
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
801008c8:	83 7d f4 0a          	cmpl   $0xa,-0xc(%ebp)
801008cc:	74 18                	je     801008e6 <consoleintr+0x139>
801008ce:	83 7d f4 04          	cmpl   $0x4,-0xc(%ebp)
801008d2:	74 12                	je     801008e6 <consoleintr+0x139>
801008d4:	a1 5c de 10 80       	mov    0x8010de5c,%eax
801008d9:	8b 15 54 de 10 80    	mov    0x8010de54,%edx
801008df:	83 ea 80             	sub    $0xffffff80,%edx
801008e2:	39 d0                	cmp    %edx,%eax
801008e4:	75 1e                	jne    80100904 <consoleintr+0x157>
          input.w = input.e;
801008e6:	a1 5c de 10 80       	mov    0x8010de5c,%eax
801008eb:	a3 58 de 10 80       	mov    %eax,0x8010de58
          wakeup(&input.r);
801008f0:	c7 04 24 54 de 10 80 	movl   $0x8010de54,(%esp)
801008f7:	e8 c4 3f 00 00       	call   801048c0 <wakeup>
        }
      }
      break;
801008fc:	eb 06                	jmp    80100904 <consoleintr+0x157>
      while(input.e != input.w &&
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
        consputc(BACKSPACE);
      }
      break;
801008fe:	90                   	nop
801008ff:	eb 04                	jmp    80100905 <consoleintr+0x158>
    case C('H'): case '\x7f':  // Backspace
      if(input.e != input.w){
        input.e--;
        consputc(BACKSPACE);
      }
      break;
80100901:	90                   	nop
80100902:	eb 01                	jmp    80100905 <consoleintr+0x158>
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
          input.w = input.e;
          wakeup(&input.r);
        }
      }
      break;
80100904:	90                   	nop
consoleintr(int (*getc)(void))
{
  int c;

  acquire(&input.lock);
  while((c = getc()) >= 0){
80100905:	8b 45 08             	mov    0x8(%ebp),%eax
80100908:	ff d0                	call   *%eax
8010090a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010090d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100911:	0f 89 ad fe ff ff    	jns    801007c4 <consoleintr+0x17>
        }
      }
      break;
    }
  }
  release(&input.lock);
80100917:	c7 04 24 a0 dd 10 80 	movl   $0x8010dda0,(%esp)
8010091e:	e8 02 42 00 00       	call   80104b25 <release>
}
80100923:	c9                   	leave  
80100924:	c3                   	ret    

80100925 <consoleread>:

int
consoleread(struct inode *ip, char *dst, int n)
{
80100925:	55                   	push   %ebp
80100926:	89 e5                	mov    %esp,%ebp
80100928:	83 ec 28             	sub    $0x28,%esp
  uint target;
  int c;

  iunlock(ip);
8010092b:	8b 45 08             	mov    0x8(%ebp),%eax
8010092e:	89 04 24             	mov    %eax,(%esp)
80100931:	e8 78 10 00 00       	call   801019ae <iunlock>
  target = n;
80100936:	8b 45 10             	mov    0x10(%ebp),%eax
80100939:	89 45 f4             	mov    %eax,-0xc(%ebp)
  acquire(&input.lock);
8010093c:	c7 04 24 a0 dd 10 80 	movl   $0x8010dda0,(%esp)
80100943:	e8 7b 41 00 00       	call   80104ac3 <acquire>
  while(n > 0){
80100948:	e9 a8 00 00 00       	jmp    801009f5 <consoleread+0xd0>
    while(input.r == input.w){
      if(proc->killed){
8010094d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100953:	8b 40 24             	mov    0x24(%eax),%eax
80100956:	85 c0                	test   %eax,%eax
80100958:	74 21                	je     8010097b <consoleread+0x56>
        release(&input.lock);
8010095a:	c7 04 24 a0 dd 10 80 	movl   $0x8010dda0,(%esp)
80100961:	e8 bf 41 00 00       	call   80104b25 <release>
        ilock(ip);
80100966:	8b 45 08             	mov    0x8(%ebp),%eax
80100969:	89 04 24             	mov    %eax,(%esp)
8010096c:	e8 ef 0e 00 00       	call   80101860 <ilock>
        return -1;
80100971:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100976:	e9 a9 00 00 00       	jmp    80100a24 <consoleread+0xff>
      }
      sleep(&input.r, &input.lock);
8010097b:	c7 44 24 04 a0 dd 10 	movl   $0x8010dda0,0x4(%esp)
80100982:	80 
80100983:	c7 04 24 54 de 10 80 	movl   $0x8010de54,(%esp)
8010098a:	e8 58 3e 00 00       	call   801047e7 <sleep>
8010098f:	eb 01                	jmp    80100992 <consoleread+0x6d>

  iunlock(ip);
  target = n;
  acquire(&input.lock);
  while(n > 0){
    while(input.r == input.w){
80100991:	90                   	nop
80100992:	8b 15 54 de 10 80    	mov    0x8010de54,%edx
80100998:	a1 58 de 10 80       	mov    0x8010de58,%eax
8010099d:	39 c2                	cmp    %eax,%edx
8010099f:	74 ac                	je     8010094d <consoleread+0x28>
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &input.lock);
    }
    c = input.buf[input.r++ % INPUT_BUF];
801009a1:	a1 54 de 10 80       	mov    0x8010de54,%eax
801009a6:	89 c2                	mov    %eax,%edx
801009a8:	83 e2 7f             	and    $0x7f,%edx
801009ab:	0f b6 92 d4 dd 10 80 	movzbl -0x7fef222c(%edx),%edx
801009b2:	0f be d2             	movsbl %dl,%edx
801009b5:	89 55 f0             	mov    %edx,-0x10(%ebp)
801009b8:	83 c0 01             	add    $0x1,%eax
801009bb:	a3 54 de 10 80       	mov    %eax,0x8010de54
    if(c == C('D')){  // EOF
801009c0:	83 7d f0 04          	cmpl   $0x4,-0x10(%ebp)
801009c4:	75 17                	jne    801009dd <consoleread+0xb8>
      if(n < target){
801009c6:	8b 45 10             	mov    0x10(%ebp),%eax
801009c9:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801009cc:	73 2f                	jae    801009fd <consoleread+0xd8>
        // Save ^D for next time, to make sure
        // caller gets a 0-byte result.
        input.r--;
801009ce:	a1 54 de 10 80       	mov    0x8010de54,%eax
801009d3:	83 e8 01             	sub    $0x1,%eax
801009d6:	a3 54 de 10 80       	mov    %eax,0x8010de54
      }
      break;
801009db:	eb 20                	jmp    801009fd <consoleread+0xd8>
    }
    *dst++ = c;
801009dd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801009e0:	89 c2                	mov    %eax,%edx
801009e2:	8b 45 0c             	mov    0xc(%ebp),%eax
801009e5:	88 10                	mov    %dl,(%eax)
801009e7:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
    --n;
801009eb:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
    if(c == '\n')
801009ef:	83 7d f0 0a          	cmpl   $0xa,-0x10(%ebp)
801009f3:	74 0b                	je     80100a00 <consoleread+0xdb>
  int c;

  iunlock(ip);
  target = n;
  acquire(&input.lock);
  while(n > 0){
801009f5:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801009f9:	7f 96                	jg     80100991 <consoleread+0x6c>
801009fb:	eb 04                	jmp    80100a01 <consoleread+0xdc>
      if(n < target){
        // Save ^D for next time, to make sure
        // caller gets a 0-byte result.
        input.r--;
      }
      break;
801009fd:	90                   	nop
801009fe:	eb 01                	jmp    80100a01 <consoleread+0xdc>
    }
    *dst++ = c;
    --n;
    if(c == '\n')
      break;
80100a00:	90                   	nop
  }
  release(&input.lock);
80100a01:	c7 04 24 a0 dd 10 80 	movl   $0x8010dda0,(%esp)
80100a08:	e8 18 41 00 00       	call   80104b25 <release>
  ilock(ip);
80100a0d:	8b 45 08             	mov    0x8(%ebp),%eax
80100a10:	89 04 24             	mov    %eax,(%esp)
80100a13:	e8 48 0e 00 00       	call   80101860 <ilock>

  return target - n;
80100a18:	8b 45 10             	mov    0x10(%ebp),%eax
80100a1b:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100a1e:	89 d1                	mov    %edx,%ecx
80100a20:	29 c1                	sub    %eax,%ecx
80100a22:	89 c8                	mov    %ecx,%eax
}
80100a24:	c9                   	leave  
80100a25:	c3                   	ret    

80100a26 <consolewrite>:

int
consolewrite(struct inode *ip, char *buf, int n)
{
80100a26:	55                   	push   %ebp
80100a27:	89 e5                	mov    %esp,%ebp
80100a29:	83 ec 28             	sub    $0x28,%esp
  int i;

  iunlock(ip);
80100a2c:	8b 45 08             	mov    0x8(%ebp),%eax
80100a2f:	89 04 24             	mov    %eax,(%esp)
80100a32:	e8 77 0f 00 00       	call   801019ae <iunlock>
  acquire(&cons.lock);
80100a37:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100a3e:	e8 80 40 00 00       	call   80104ac3 <acquire>
  for(i = 0; i < n; i++)
80100a43:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80100a4a:	eb 1d                	jmp    80100a69 <consolewrite+0x43>
    consputc(buf[i] & 0xff);
80100a4c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100a4f:	03 45 0c             	add    0xc(%ebp),%eax
80100a52:	0f b6 00             	movzbl (%eax),%eax
80100a55:	0f be c0             	movsbl %al,%eax
80100a58:	25 ff 00 00 00       	and    $0xff,%eax
80100a5d:	89 04 24             	mov    %eax,(%esp)
80100a60:	e8 eb fc ff ff       	call   80100750 <consputc>
{
  int i;

  iunlock(ip);
  acquire(&cons.lock);
  for(i = 0; i < n; i++)
80100a65:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100a69:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100a6c:	3b 45 10             	cmp    0x10(%ebp),%eax
80100a6f:	7c db                	jl     80100a4c <consolewrite+0x26>
    consputc(buf[i] & 0xff);
  release(&cons.lock);
80100a71:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100a78:	e8 a8 40 00 00       	call   80104b25 <release>
  ilock(ip);
80100a7d:	8b 45 08             	mov    0x8(%ebp),%eax
80100a80:	89 04 24             	mov    %eax,(%esp)
80100a83:	e8 d8 0d 00 00       	call   80101860 <ilock>

  return n;
80100a88:	8b 45 10             	mov    0x10(%ebp),%eax
}
80100a8b:	c9                   	leave  
80100a8c:	c3                   	ret    

80100a8d <consoleinit>:

void
consoleinit(void)
{
80100a8d:	55                   	push   %ebp
80100a8e:	89 e5                	mov    %esp,%ebp
80100a90:	83 ec 18             	sub    $0x18,%esp
  initlock(&cons.lock, "console");
80100a93:	c7 44 24 04 c7 80 10 	movl   $0x801080c7,0x4(%esp)
80100a9a:	80 
80100a9b:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100aa2:	e8 fb 3f 00 00       	call   80104aa2 <initlock>
  initlock(&input.lock, "input");
80100aa7:	c7 44 24 04 cf 80 10 	movl   $0x801080cf,0x4(%esp)
80100aae:	80 
80100aaf:	c7 04 24 a0 dd 10 80 	movl   $0x8010dda0,(%esp)
80100ab6:	e8 e7 3f 00 00       	call   80104aa2 <initlock>

  devsw[CONSOLE].write = consolewrite;
80100abb:	c7 05 0c e8 10 80 26 	movl   $0x80100a26,0x8010e80c
80100ac2:	0a 10 80 
  devsw[CONSOLE].read = consoleread;
80100ac5:	c7 05 08 e8 10 80 25 	movl   $0x80100925,0x8010e808
80100acc:	09 10 80 
  cons.locking = 1;
80100acf:	c7 05 f4 b5 10 80 01 	movl   $0x1,0x8010b5f4
80100ad6:	00 00 00 

  picenable(IRQ_KBD);
80100ad9:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100ae0:	e8 c4 2f 00 00       	call   80103aa9 <picenable>
  ioapicenable(IRQ_KBD, 0);
80100ae5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80100aec:	00 
80100aed:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100af4:	e8 75 1e 00 00       	call   8010296e <ioapicenable>
}
80100af9:	c9                   	leave  
80100afa:	c3                   	ret    
	...

80100afc <exec>:
#include "x86.h"
#include "elf.h"

int
exec(char *path, char **argv)
{
80100afc:	55                   	push   %ebp
80100afd:	89 e5                	mov    %esp,%ebp
80100aff:	81 ec 38 01 00 00    	sub    $0x138,%esp
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pde_t *pgdir, *oldpgdir;

  if((ip = namei(path)) == 0)
80100b05:	8b 45 08             	mov    0x8(%ebp),%eax
80100b08:	89 04 24             	mov    %eax,(%esp)
80100b0b:	e8 f2 18 00 00       	call   80102402 <namei>
80100b10:	89 45 d8             	mov    %eax,-0x28(%ebp)
80100b13:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100b17:	75 0a                	jne    80100b23 <exec+0x27>
    return -1;
80100b19:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100b1e:	e9 d3 03 00 00       	jmp    80100ef6 <exec+0x3fa>
  ilock(ip);
80100b23:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100b26:	89 04 24             	mov    %eax,(%esp)
80100b29:	e8 32 0d 00 00       	call   80101860 <ilock>
  pgdir = 0;
80100b2e:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) < sizeof(elf))
80100b35:	c7 44 24 0c 34 00 00 	movl   $0x34,0xc(%esp)
80100b3c:	00 
80100b3d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80100b44:	00 
80100b45:	8d 85 0c ff ff ff    	lea    -0xf4(%ebp),%eax
80100b4b:	89 44 24 04          	mov    %eax,0x4(%esp)
80100b4f:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100b52:	89 04 24             	mov    %eax,(%esp)
80100b55:	e8 fc 11 00 00       	call   80101d56 <readi>
80100b5a:	83 f8 33             	cmp    $0x33,%eax
80100b5d:	0f 86 4d 03 00 00    	jbe    80100eb0 <exec+0x3b4>
    goto bad;
  if(elf.magic != ELF_MAGIC)
80100b63:	8b 85 0c ff ff ff    	mov    -0xf4(%ebp),%eax
80100b69:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
80100b6e:	0f 85 3f 03 00 00    	jne    80100eb3 <exec+0x3b7>
    goto bad;

  if((pgdir = setupkvm()) == 0)
80100b74:	e8 98 6c 00 00       	call   80107811 <setupkvm>
80100b79:	89 45 d4             	mov    %eax,-0x2c(%ebp)
80100b7c:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100b80:	0f 84 30 03 00 00    	je     80100eb6 <exec+0x3ba>
    goto bad;

  // Load program into memory.
  sz = 0;
80100b86:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100b8d:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80100b94:	8b 85 28 ff ff ff    	mov    -0xd8(%ebp),%eax
80100b9a:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100b9d:	e9 c5 00 00 00       	jmp    80100c67 <exec+0x16b>
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
80100ba2:	8b 45 e8             	mov    -0x18(%ebp),%eax
80100ba5:	c7 44 24 0c 20 00 00 	movl   $0x20,0xc(%esp)
80100bac:	00 
80100bad:	89 44 24 08          	mov    %eax,0x8(%esp)
80100bb1:	8d 85 ec fe ff ff    	lea    -0x114(%ebp),%eax
80100bb7:	89 44 24 04          	mov    %eax,0x4(%esp)
80100bbb:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100bbe:	89 04 24             	mov    %eax,(%esp)
80100bc1:	e8 90 11 00 00       	call   80101d56 <readi>
80100bc6:	83 f8 20             	cmp    $0x20,%eax
80100bc9:	0f 85 ea 02 00 00    	jne    80100eb9 <exec+0x3bd>
      goto bad;
    if(ph.type != ELF_PROG_LOAD)
80100bcf:	8b 85 ec fe ff ff    	mov    -0x114(%ebp),%eax
80100bd5:	83 f8 01             	cmp    $0x1,%eax
80100bd8:	75 7f                	jne    80100c59 <exec+0x15d>
      continue;
    if(ph.memsz < ph.filesz)
80100bda:	8b 95 00 ff ff ff    	mov    -0x100(%ebp),%edx
80100be0:	8b 85 fc fe ff ff    	mov    -0x104(%ebp),%eax
80100be6:	39 c2                	cmp    %eax,%edx
80100be8:	0f 82 ce 02 00 00    	jb     80100ebc <exec+0x3c0>
      goto bad;
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
80100bee:	8b 95 f4 fe ff ff    	mov    -0x10c(%ebp),%edx
80100bf4:	8b 85 00 ff ff ff    	mov    -0x100(%ebp),%eax
80100bfa:	01 d0                	add    %edx,%eax
80100bfc:	89 44 24 08          	mov    %eax,0x8(%esp)
80100c00:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100c03:	89 44 24 04          	mov    %eax,0x4(%esp)
80100c07:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100c0a:	89 04 24             	mov    %eax,(%esp)
80100c0d:	e8 d1 6f 00 00       	call   80107be3 <allocuvm>
80100c12:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100c15:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100c19:	0f 84 a0 02 00 00    	je     80100ebf <exec+0x3c3>
      goto bad;
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
80100c1f:	8b 8d fc fe ff ff    	mov    -0x104(%ebp),%ecx
80100c25:	8b 95 f0 fe ff ff    	mov    -0x110(%ebp),%edx
80100c2b:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
80100c31:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80100c35:	89 54 24 0c          	mov    %edx,0xc(%esp)
80100c39:	8b 55 d8             	mov    -0x28(%ebp),%edx
80100c3c:	89 54 24 08          	mov    %edx,0x8(%esp)
80100c40:	89 44 24 04          	mov    %eax,0x4(%esp)
80100c44:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100c47:	89 04 24             	mov    %eax,(%esp)
80100c4a:	e8 a5 6e 00 00       	call   80107af4 <loaduvm>
80100c4f:	85 c0                	test   %eax,%eax
80100c51:	0f 88 6b 02 00 00    	js     80100ec2 <exec+0x3c6>
80100c57:	eb 01                	jmp    80100c5a <exec+0x15e>
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
      goto bad;
    if(ph.type != ELF_PROG_LOAD)
      continue;
80100c59:	90                   	nop
  if((pgdir = setupkvm()) == 0)
    goto bad;

  // Load program into memory.
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100c5a:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
80100c5e:	8b 45 e8             	mov    -0x18(%ebp),%eax
80100c61:	83 c0 20             	add    $0x20,%eax
80100c64:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100c67:	0f b7 85 38 ff ff ff 	movzwl -0xc8(%ebp),%eax
80100c6e:	0f b7 c0             	movzwl %ax,%eax
80100c71:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80100c74:	0f 8f 28 ff ff ff    	jg     80100ba2 <exec+0xa6>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
      goto bad;
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
      goto bad;
  }
  iunlockput(ip);
80100c7a:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100c7d:	89 04 24             	mov    %eax,(%esp)
80100c80:	e8 5f 0e 00 00       	call   80101ae4 <iunlockput>
  ip = 0;
80100c85:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)

  // Allocate two pages at the next page boundary.
  // Make the first inaccessible.  Use the second as the user stack.
  sz = PGROUNDUP(sz);
80100c8c:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100c8f:	05 ff 0f 00 00       	add    $0xfff,%eax
80100c94:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80100c99:	89 45 e0             	mov    %eax,-0x20(%ebp)
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
80100c9c:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100c9f:	05 00 20 00 00       	add    $0x2000,%eax
80100ca4:	89 44 24 08          	mov    %eax,0x8(%esp)
80100ca8:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100cab:	89 44 24 04          	mov    %eax,0x4(%esp)
80100caf:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100cb2:	89 04 24             	mov    %eax,(%esp)
80100cb5:	e8 29 6f 00 00       	call   80107be3 <allocuvm>
80100cba:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100cbd:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100cc1:	0f 84 fe 01 00 00    	je     80100ec5 <exec+0x3c9>
    goto bad;
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100cc7:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100cca:	2d 00 20 00 00       	sub    $0x2000,%eax
80100ccf:	89 44 24 04          	mov    %eax,0x4(%esp)
80100cd3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100cd6:	89 04 24             	mov    %eax,(%esp)
80100cd9:	e8 29 71 00 00       	call   80107e07 <clearpteu>
  sp = sz;
80100cde:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100ce1:	89 45 dc             	mov    %eax,-0x24(%ebp)

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100ce4:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80100ceb:	e9 81 00 00 00       	jmp    80100d71 <exec+0x275>
    if(argc >= MAXARG)
80100cf0:	83 7d e4 1f          	cmpl   $0x1f,-0x1c(%ebp)
80100cf4:	0f 87 ce 01 00 00    	ja     80100ec8 <exec+0x3cc>
      goto bad;
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
80100cfa:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100cfd:	c1 e0 02             	shl    $0x2,%eax
80100d00:	03 45 0c             	add    0xc(%ebp),%eax
80100d03:	8b 00                	mov    (%eax),%eax
80100d05:	89 04 24             	mov    %eax,(%esp)
80100d08:	e8 83 42 00 00       	call   80104f90 <strlen>
80100d0d:	f7 d0                	not    %eax
80100d0f:	03 45 dc             	add    -0x24(%ebp),%eax
80100d12:	83 e0 fc             	and    $0xfffffffc,%eax
80100d15:	89 45 dc             	mov    %eax,-0x24(%ebp)
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100d18:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d1b:	c1 e0 02             	shl    $0x2,%eax
80100d1e:	03 45 0c             	add    0xc(%ebp),%eax
80100d21:	8b 00                	mov    (%eax),%eax
80100d23:	89 04 24             	mov    %eax,(%esp)
80100d26:	e8 65 42 00 00       	call   80104f90 <strlen>
80100d2b:	83 c0 01             	add    $0x1,%eax
80100d2e:	89 c2                	mov    %eax,%edx
80100d30:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d33:	c1 e0 02             	shl    $0x2,%eax
80100d36:	03 45 0c             	add    0xc(%ebp),%eax
80100d39:	8b 00                	mov    (%eax),%eax
80100d3b:	89 54 24 0c          	mov    %edx,0xc(%esp)
80100d3f:	89 44 24 08          	mov    %eax,0x8(%esp)
80100d43:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100d46:	89 44 24 04          	mov    %eax,0x4(%esp)
80100d4a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100d4d:	89 04 24             	mov    %eax,(%esp)
80100d50:	e8 77 72 00 00       	call   80107fcc <copyout>
80100d55:	85 c0                	test   %eax,%eax
80100d57:	0f 88 6e 01 00 00    	js     80100ecb <exec+0x3cf>
      goto bad;
    ustack[3+argc] = sp;
80100d5d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d60:	8d 50 03             	lea    0x3(%eax),%edx
80100d63:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100d66:	89 84 95 40 ff ff ff 	mov    %eax,-0xc0(%ebp,%edx,4)
    goto bad;
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
  sp = sz;

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100d6d:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80100d71:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d74:	c1 e0 02             	shl    $0x2,%eax
80100d77:	03 45 0c             	add    0xc(%ebp),%eax
80100d7a:	8b 00                	mov    (%eax),%eax
80100d7c:	85 c0                	test   %eax,%eax
80100d7e:	0f 85 6c ff ff ff    	jne    80100cf0 <exec+0x1f4>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
    ustack[3+argc] = sp;
  }
  ustack[3+argc] = 0;
80100d84:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d87:	83 c0 03             	add    $0x3,%eax
80100d8a:	c7 84 85 40 ff ff ff 	movl   $0x0,-0xc0(%ebp,%eax,4)
80100d91:	00 00 00 00 

  ustack[0] = 0xffffffff;  // fake return PC
80100d95:	c7 85 40 ff ff ff ff 	movl   $0xffffffff,-0xc0(%ebp)
80100d9c:	ff ff ff 
  ustack[1] = argc;
80100d9f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100da2:	89 85 44 ff ff ff    	mov    %eax,-0xbc(%ebp)
  ustack[2] = sp - (argc+1)*4;  // argv pointer
80100da8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dab:	83 c0 01             	add    $0x1,%eax
80100dae:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100db5:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100db8:	29 d0                	sub    %edx,%eax
80100dba:	89 85 48 ff ff ff    	mov    %eax,-0xb8(%ebp)

  sp -= (3+argc+1) * 4;
80100dc0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dc3:	83 c0 04             	add    $0x4,%eax
80100dc6:	c1 e0 02             	shl    $0x2,%eax
80100dc9:	29 45 dc             	sub    %eax,-0x24(%ebp)
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
80100dcc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dcf:	83 c0 04             	add    $0x4,%eax
80100dd2:	c1 e0 02             	shl    $0x2,%eax
80100dd5:	89 44 24 0c          	mov    %eax,0xc(%esp)
80100dd9:	8d 85 40 ff ff ff    	lea    -0xc0(%ebp),%eax
80100ddf:	89 44 24 08          	mov    %eax,0x8(%esp)
80100de3:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100de6:	89 44 24 04          	mov    %eax,0x4(%esp)
80100dea:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100ded:	89 04 24             	mov    %eax,(%esp)
80100df0:	e8 d7 71 00 00       	call   80107fcc <copyout>
80100df5:	85 c0                	test   %eax,%eax
80100df7:	0f 88 d1 00 00 00    	js     80100ece <exec+0x3d2>
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100dfd:	8b 45 08             	mov    0x8(%ebp),%eax
80100e00:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100e03:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e06:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100e09:	eb 17                	jmp    80100e22 <exec+0x326>
    if(*s == '/')
80100e0b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e0e:	0f b6 00             	movzbl (%eax),%eax
80100e11:	3c 2f                	cmp    $0x2f,%al
80100e13:	75 09                	jne    80100e1e <exec+0x322>
      last = s+1;
80100e15:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e18:	83 c0 01             	add    $0x1,%eax
80100e1b:	89 45 f0             	mov    %eax,-0x10(%ebp)
  sp -= (3+argc+1) * 4;
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100e1e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100e22:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e25:	0f b6 00             	movzbl (%eax),%eax
80100e28:	84 c0                	test   %al,%al
80100e2a:	75 df                	jne    80100e0b <exec+0x30f>
    if(*s == '/')
      last = s+1;
  safestrcpy(proc->name, last, sizeof(proc->name));
80100e2c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e32:	8d 50 6c             	lea    0x6c(%eax),%edx
80100e35:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80100e3c:	00 
80100e3d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100e40:	89 44 24 04          	mov    %eax,0x4(%esp)
80100e44:	89 14 24             	mov    %edx,(%esp)
80100e47:	e8 f6 40 00 00       	call   80104f42 <safestrcpy>

  // Commit to the user image.
  oldpgdir = proc->pgdir;
80100e4c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e52:	8b 40 04             	mov    0x4(%eax),%eax
80100e55:	89 45 d0             	mov    %eax,-0x30(%ebp)
  proc->pgdir = pgdir;
80100e58:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e5e:	8b 55 d4             	mov    -0x2c(%ebp),%edx
80100e61:	89 50 04             	mov    %edx,0x4(%eax)
  proc->sz = sz;
80100e64:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e6a:	8b 55 e0             	mov    -0x20(%ebp),%edx
80100e6d:	89 10                	mov    %edx,(%eax)
  proc->tf->eip = elf.entry;  // main
80100e6f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e75:	8b 40 18             	mov    0x18(%eax),%eax
80100e78:	8b 95 24 ff ff ff    	mov    -0xdc(%ebp),%edx
80100e7e:	89 50 38             	mov    %edx,0x38(%eax)
  proc->tf->esp = sp;
80100e81:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e87:	8b 40 18             	mov    0x18(%eax),%eax
80100e8a:	8b 55 dc             	mov    -0x24(%ebp),%edx
80100e8d:	89 50 44             	mov    %edx,0x44(%eax)
  switchuvm(proc);
80100e90:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e96:	89 04 24             	mov    %eax,(%esp)
80100e99:	e8 64 6a 00 00       	call   80107902 <switchuvm>
  freevm(oldpgdir);
80100e9e:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100ea1:	89 04 24             	mov    %eax,(%esp)
80100ea4:	e8 d0 6e 00 00       	call   80107d79 <freevm>
  return 0;
80100ea9:	b8 00 00 00 00       	mov    $0x0,%eax
80100eae:	eb 46                	jmp    80100ef6 <exec+0x3fa>
  ilock(ip);
  pgdir = 0;

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) < sizeof(elf))
    goto bad;
80100eb0:	90                   	nop
80100eb1:	eb 1c                	jmp    80100ecf <exec+0x3d3>
  if(elf.magic != ELF_MAGIC)
    goto bad;
80100eb3:	90                   	nop
80100eb4:	eb 19                	jmp    80100ecf <exec+0x3d3>

  if((pgdir = setupkvm()) == 0)
    goto bad;
80100eb6:	90                   	nop
80100eb7:	eb 16                	jmp    80100ecf <exec+0x3d3>

  // Load program into memory.
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
      goto bad;
80100eb9:	90                   	nop
80100eba:	eb 13                	jmp    80100ecf <exec+0x3d3>
    if(ph.type != ELF_PROG_LOAD)
      continue;
    if(ph.memsz < ph.filesz)
      goto bad;
80100ebc:	90                   	nop
80100ebd:	eb 10                	jmp    80100ecf <exec+0x3d3>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
      goto bad;
80100ebf:	90                   	nop
80100ec0:	eb 0d                	jmp    80100ecf <exec+0x3d3>
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
      goto bad;
80100ec2:	90                   	nop
80100ec3:	eb 0a                	jmp    80100ecf <exec+0x3d3>

  // Allocate two pages at the next page boundary.
  // Make the first inaccessible.  Use the second as the user stack.
  sz = PGROUNDUP(sz);
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
    goto bad;
80100ec5:	90                   	nop
80100ec6:	eb 07                	jmp    80100ecf <exec+0x3d3>
  sp = sz;

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
    if(argc >= MAXARG)
      goto bad;
80100ec8:	90                   	nop
80100ec9:	eb 04                	jmp    80100ecf <exec+0x3d3>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
80100ecb:	90                   	nop
80100ecc:	eb 01                	jmp    80100ecf <exec+0x3d3>
  ustack[1] = argc;
  ustack[2] = sp - (argc+1)*4;  // argv pointer

  sp -= (3+argc+1) * 4;
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
    goto bad;
80100ece:	90                   	nop
  switchuvm(proc);
  freevm(oldpgdir);
  return 0;

 bad:
  if(pgdir)
80100ecf:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100ed3:	74 0b                	je     80100ee0 <exec+0x3e4>
    freevm(pgdir);
80100ed5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100ed8:	89 04 24             	mov    %eax,(%esp)
80100edb:	e8 99 6e 00 00       	call   80107d79 <freevm>
  if(ip)
80100ee0:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100ee4:	74 0b                	je     80100ef1 <exec+0x3f5>
    iunlockput(ip);
80100ee6:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100ee9:	89 04 24             	mov    %eax,(%esp)
80100eec:	e8 f3 0b 00 00       	call   80101ae4 <iunlockput>
  return -1;
80100ef1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80100ef6:	c9                   	leave  
80100ef7:	c3                   	ret    

80100ef8 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
80100ef8:	55                   	push   %ebp
80100ef9:	89 e5                	mov    %esp,%ebp
80100efb:	83 ec 18             	sub    $0x18,%esp
  initlock(&ftable.lock, "ftable");
80100efe:	c7 44 24 04 d5 80 10 	movl   $0x801080d5,0x4(%esp)
80100f05:	80 
80100f06:	c7 04 24 60 de 10 80 	movl   $0x8010de60,(%esp)
80100f0d:	e8 90 3b 00 00       	call   80104aa2 <initlock>
}
80100f12:	c9                   	leave  
80100f13:	c3                   	ret    

80100f14 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
80100f14:	55                   	push   %ebp
80100f15:	89 e5                	mov    %esp,%ebp
80100f17:	83 ec 28             	sub    $0x28,%esp
  struct file *f;

  acquire(&ftable.lock);
80100f1a:	c7 04 24 60 de 10 80 	movl   $0x8010de60,(%esp)
80100f21:	e8 9d 3b 00 00       	call   80104ac3 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100f26:	c7 45 f4 94 de 10 80 	movl   $0x8010de94,-0xc(%ebp)
80100f2d:	eb 29                	jmp    80100f58 <filealloc+0x44>
    if(f->ref == 0){
80100f2f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f32:	8b 40 04             	mov    0x4(%eax),%eax
80100f35:	85 c0                	test   %eax,%eax
80100f37:	75 1b                	jne    80100f54 <filealloc+0x40>
      f->ref = 1;
80100f39:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f3c:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
      release(&ftable.lock);
80100f43:	c7 04 24 60 de 10 80 	movl   $0x8010de60,(%esp)
80100f4a:	e8 d6 3b 00 00       	call   80104b25 <release>
      return f;
80100f4f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f52:	eb 1e                	jmp    80100f72 <filealloc+0x5e>
filealloc(void)
{
  struct file *f;

  acquire(&ftable.lock);
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100f54:	83 45 f4 18          	addl   $0x18,-0xc(%ebp)
80100f58:	81 7d f4 f4 e7 10 80 	cmpl   $0x8010e7f4,-0xc(%ebp)
80100f5f:	72 ce                	jb     80100f2f <filealloc+0x1b>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
80100f61:	c7 04 24 60 de 10 80 	movl   $0x8010de60,(%esp)
80100f68:	e8 b8 3b 00 00       	call   80104b25 <release>
  return 0;
80100f6d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80100f72:	c9                   	leave  
80100f73:	c3                   	ret    

80100f74 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
80100f74:	55                   	push   %ebp
80100f75:	89 e5                	mov    %esp,%ebp
80100f77:	83 ec 18             	sub    $0x18,%esp
  acquire(&ftable.lock);
80100f7a:	c7 04 24 60 de 10 80 	movl   $0x8010de60,(%esp)
80100f81:	e8 3d 3b 00 00       	call   80104ac3 <acquire>
  if(f->ref < 1)
80100f86:	8b 45 08             	mov    0x8(%ebp),%eax
80100f89:	8b 40 04             	mov    0x4(%eax),%eax
80100f8c:	85 c0                	test   %eax,%eax
80100f8e:	7f 0c                	jg     80100f9c <filedup+0x28>
    panic("filedup");
80100f90:	c7 04 24 dc 80 10 80 	movl   $0x801080dc,(%esp)
80100f97:	e8 a1 f5 ff ff       	call   8010053d <panic>
  f->ref++;
80100f9c:	8b 45 08             	mov    0x8(%ebp),%eax
80100f9f:	8b 40 04             	mov    0x4(%eax),%eax
80100fa2:	8d 50 01             	lea    0x1(%eax),%edx
80100fa5:	8b 45 08             	mov    0x8(%ebp),%eax
80100fa8:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
80100fab:	c7 04 24 60 de 10 80 	movl   $0x8010de60,(%esp)
80100fb2:	e8 6e 3b 00 00       	call   80104b25 <release>
  return f;
80100fb7:	8b 45 08             	mov    0x8(%ebp),%eax
}
80100fba:	c9                   	leave  
80100fbb:	c3                   	ret    

80100fbc <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
80100fbc:	55                   	push   %ebp
80100fbd:	89 e5                	mov    %esp,%ebp
80100fbf:	83 ec 38             	sub    $0x38,%esp
  struct file ff;

  acquire(&ftable.lock);
80100fc2:	c7 04 24 60 de 10 80 	movl   $0x8010de60,(%esp)
80100fc9:	e8 f5 3a 00 00       	call   80104ac3 <acquire>
  if(f->ref < 1)
80100fce:	8b 45 08             	mov    0x8(%ebp),%eax
80100fd1:	8b 40 04             	mov    0x4(%eax),%eax
80100fd4:	85 c0                	test   %eax,%eax
80100fd6:	7f 0c                	jg     80100fe4 <fileclose+0x28>
    panic("fileclose");
80100fd8:	c7 04 24 e4 80 10 80 	movl   $0x801080e4,(%esp)
80100fdf:	e8 59 f5 ff ff       	call   8010053d <panic>
  if(--f->ref > 0){
80100fe4:	8b 45 08             	mov    0x8(%ebp),%eax
80100fe7:	8b 40 04             	mov    0x4(%eax),%eax
80100fea:	8d 50 ff             	lea    -0x1(%eax),%edx
80100fed:	8b 45 08             	mov    0x8(%ebp),%eax
80100ff0:	89 50 04             	mov    %edx,0x4(%eax)
80100ff3:	8b 45 08             	mov    0x8(%ebp),%eax
80100ff6:	8b 40 04             	mov    0x4(%eax),%eax
80100ff9:	85 c0                	test   %eax,%eax
80100ffb:	7e 11                	jle    8010100e <fileclose+0x52>
    release(&ftable.lock);
80100ffd:	c7 04 24 60 de 10 80 	movl   $0x8010de60,(%esp)
80101004:	e8 1c 3b 00 00       	call   80104b25 <release>
    return;
80101009:	e9 82 00 00 00       	jmp    80101090 <fileclose+0xd4>
  }
  ff = *f;
8010100e:	8b 45 08             	mov    0x8(%ebp),%eax
80101011:	8b 10                	mov    (%eax),%edx
80101013:	89 55 e0             	mov    %edx,-0x20(%ebp)
80101016:	8b 50 04             	mov    0x4(%eax),%edx
80101019:	89 55 e4             	mov    %edx,-0x1c(%ebp)
8010101c:	8b 50 08             	mov    0x8(%eax),%edx
8010101f:	89 55 e8             	mov    %edx,-0x18(%ebp)
80101022:	8b 50 0c             	mov    0xc(%eax),%edx
80101025:	89 55 ec             	mov    %edx,-0x14(%ebp)
80101028:	8b 50 10             	mov    0x10(%eax),%edx
8010102b:	89 55 f0             	mov    %edx,-0x10(%ebp)
8010102e:	8b 40 14             	mov    0x14(%eax),%eax
80101031:	89 45 f4             	mov    %eax,-0xc(%ebp)
  f->ref = 0;
80101034:	8b 45 08             	mov    0x8(%ebp),%eax
80101037:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
  f->type = FD_NONE;
8010103e:	8b 45 08             	mov    0x8(%ebp),%eax
80101041:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  release(&ftable.lock);
80101047:	c7 04 24 60 de 10 80 	movl   $0x8010de60,(%esp)
8010104e:	e8 d2 3a 00 00       	call   80104b25 <release>
  
  if(ff.type == FD_PIPE)
80101053:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101056:	83 f8 01             	cmp    $0x1,%eax
80101059:	75 18                	jne    80101073 <fileclose+0xb7>
    pipeclose(ff.pipe, ff.writable);
8010105b:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
8010105f:	0f be d0             	movsbl %al,%edx
80101062:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101065:	89 54 24 04          	mov    %edx,0x4(%esp)
80101069:	89 04 24             	mov    %eax,(%esp)
8010106c:	e8 f2 2c 00 00       	call   80103d63 <pipeclose>
80101071:	eb 1d                	jmp    80101090 <fileclose+0xd4>
  else if(ff.type == FD_INODE){
80101073:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101076:	83 f8 02             	cmp    $0x2,%eax
80101079:	75 15                	jne    80101090 <fileclose+0xd4>
    begin_trans();
8010107b:	e8 95 21 00 00       	call   80103215 <begin_trans>
    iput(ff.ip);
80101080:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101083:	89 04 24             	mov    %eax,(%esp)
80101086:	e8 88 09 00 00       	call   80101a13 <iput>
    commit_trans();
8010108b:	e8 ce 21 00 00       	call   8010325e <commit_trans>
  }
}
80101090:	c9                   	leave  
80101091:	c3                   	ret    

80101092 <filestat>:

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
80101092:	55                   	push   %ebp
80101093:	89 e5                	mov    %esp,%ebp
80101095:	83 ec 18             	sub    $0x18,%esp
  if(f->type == FD_INODE){
80101098:	8b 45 08             	mov    0x8(%ebp),%eax
8010109b:	8b 00                	mov    (%eax),%eax
8010109d:	83 f8 02             	cmp    $0x2,%eax
801010a0:	75 38                	jne    801010da <filestat+0x48>
    ilock(f->ip);
801010a2:	8b 45 08             	mov    0x8(%ebp),%eax
801010a5:	8b 40 10             	mov    0x10(%eax),%eax
801010a8:	89 04 24             	mov    %eax,(%esp)
801010ab:	e8 b0 07 00 00       	call   80101860 <ilock>
    stati(f->ip, st);
801010b0:	8b 45 08             	mov    0x8(%ebp),%eax
801010b3:	8b 40 10             	mov    0x10(%eax),%eax
801010b6:	8b 55 0c             	mov    0xc(%ebp),%edx
801010b9:	89 54 24 04          	mov    %edx,0x4(%esp)
801010bd:	89 04 24             	mov    %eax,(%esp)
801010c0:	e8 4c 0c 00 00       	call   80101d11 <stati>
    iunlock(f->ip);
801010c5:	8b 45 08             	mov    0x8(%ebp),%eax
801010c8:	8b 40 10             	mov    0x10(%eax),%eax
801010cb:	89 04 24             	mov    %eax,(%esp)
801010ce:	e8 db 08 00 00       	call   801019ae <iunlock>
    return 0;
801010d3:	b8 00 00 00 00       	mov    $0x0,%eax
801010d8:	eb 05                	jmp    801010df <filestat+0x4d>
  }
  return -1;
801010da:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801010df:	c9                   	leave  
801010e0:	c3                   	ret    

801010e1 <fileread>:

// Read from file f.
int
fileread(struct file *f, char *addr, int n)
{
801010e1:	55                   	push   %ebp
801010e2:	89 e5                	mov    %esp,%ebp
801010e4:	83 ec 28             	sub    $0x28,%esp
  int r;

  if(f->readable == 0)
801010e7:	8b 45 08             	mov    0x8(%ebp),%eax
801010ea:	0f b6 40 08          	movzbl 0x8(%eax),%eax
801010ee:	84 c0                	test   %al,%al
801010f0:	75 0a                	jne    801010fc <fileread+0x1b>
    return -1;
801010f2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801010f7:	e9 9f 00 00 00       	jmp    8010119b <fileread+0xba>
  if(f->type == FD_PIPE)
801010fc:	8b 45 08             	mov    0x8(%ebp),%eax
801010ff:	8b 00                	mov    (%eax),%eax
80101101:	83 f8 01             	cmp    $0x1,%eax
80101104:	75 1e                	jne    80101124 <fileread+0x43>
    return piperead(f->pipe, addr, n);
80101106:	8b 45 08             	mov    0x8(%ebp),%eax
80101109:	8b 40 0c             	mov    0xc(%eax),%eax
8010110c:	8b 55 10             	mov    0x10(%ebp),%edx
8010110f:	89 54 24 08          	mov    %edx,0x8(%esp)
80101113:	8b 55 0c             	mov    0xc(%ebp),%edx
80101116:	89 54 24 04          	mov    %edx,0x4(%esp)
8010111a:	89 04 24             	mov    %eax,(%esp)
8010111d:	e8 c3 2d 00 00       	call   80103ee5 <piperead>
80101122:	eb 77                	jmp    8010119b <fileread+0xba>
  if(f->type == FD_INODE){
80101124:	8b 45 08             	mov    0x8(%ebp),%eax
80101127:	8b 00                	mov    (%eax),%eax
80101129:	83 f8 02             	cmp    $0x2,%eax
8010112c:	75 61                	jne    8010118f <fileread+0xae>
    ilock(f->ip);
8010112e:	8b 45 08             	mov    0x8(%ebp),%eax
80101131:	8b 40 10             	mov    0x10(%eax),%eax
80101134:	89 04 24             	mov    %eax,(%esp)
80101137:	e8 24 07 00 00       	call   80101860 <ilock>
    if((r = readi(f->ip, addr, f->off, n)) > 0)
8010113c:	8b 4d 10             	mov    0x10(%ebp),%ecx
8010113f:	8b 45 08             	mov    0x8(%ebp),%eax
80101142:	8b 50 14             	mov    0x14(%eax),%edx
80101145:	8b 45 08             	mov    0x8(%ebp),%eax
80101148:	8b 40 10             	mov    0x10(%eax),%eax
8010114b:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
8010114f:	89 54 24 08          	mov    %edx,0x8(%esp)
80101153:	8b 55 0c             	mov    0xc(%ebp),%edx
80101156:	89 54 24 04          	mov    %edx,0x4(%esp)
8010115a:	89 04 24             	mov    %eax,(%esp)
8010115d:	e8 f4 0b 00 00       	call   80101d56 <readi>
80101162:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101165:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101169:	7e 11                	jle    8010117c <fileread+0x9b>
      f->off += r;
8010116b:	8b 45 08             	mov    0x8(%ebp),%eax
8010116e:	8b 50 14             	mov    0x14(%eax),%edx
80101171:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101174:	01 c2                	add    %eax,%edx
80101176:	8b 45 08             	mov    0x8(%ebp),%eax
80101179:	89 50 14             	mov    %edx,0x14(%eax)
    iunlock(f->ip);
8010117c:	8b 45 08             	mov    0x8(%ebp),%eax
8010117f:	8b 40 10             	mov    0x10(%eax),%eax
80101182:	89 04 24             	mov    %eax,(%esp)
80101185:	e8 24 08 00 00       	call   801019ae <iunlock>
    return r;
8010118a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010118d:	eb 0c                	jmp    8010119b <fileread+0xba>
  }
  panic("fileread");
8010118f:	c7 04 24 ee 80 10 80 	movl   $0x801080ee,(%esp)
80101196:	e8 a2 f3 ff ff       	call   8010053d <panic>
}
8010119b:	c9                   	leave  
8010119c:	c3                   	ret    

8010119d <filewrite>:

//PAGEBREAK!
// Write to file f.
int
filewrite(struct file *f, char *addr, int n)
{
8010119d:	55                   	push   %ebp
8010119e:	89 e5                	mov    %esp,%ebp
801011a0:	53                   	push   %ebx
801011a1:	83 ec 24             	sub    $0x24,%esp
  int r;

  if(f->writable == 0)
801011a4:	8b 45 08             	mov    0x8(%ebp),%eax
801011a7:	0f b6 40 09          	movzbl 0x9(%eax),%eax
801011ab:	84 c0                	test   %al,%al
801011ad:	75 0a                	jne    801011b9 <filewrite+0x1c>
    return -1;
801011af:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801011b4:	e9 23 01 00 00       	jmp    801012dc <filewrite+0x13f>
  if(f->type == FD_PIPE)
801011b9:	8b 45 08             	mov    0x8(%ebp),%eax
801011bc:	8b 00                	mov    (%eax),%eax
801011be:	83 f8 01             	cmp    $0x1,%eax
801011c1:	75 21                	jne    801011e4 <filewrite+0x47>
    return pipewrite(f->pipe, addr, n);
801011c3:	8b 45 08             	mov    0x8(%ebp),%eax
801011c6:	8b 40 0c             	mov    0xc(%eax),%eax
801011c9:	8b 55 10             	mov    0x10(%ebp),%edx
801011cc:	89 54 24 08          	mov    %edx,0x8(%esp)
801011d0:	8b 55 0c             	mov    0xc(%ebp),%edx
801011d3:	89 54 24 04          	mov    %edx,0x4(%esp)
801011d7:	89 04 24             	mov    %eax,(%esp)
801011da:	e8 16 2c 00 00       	call   80103df5 <pipewrite>
801011df:	e9 f8 00 00 00       	jmp    801012dc <filewrite+0x13f>
  if(f->type == FD_INODE){
801011e4:	8b 45 08             	mov    0x8(%ebp),%eax
801011e7:	8b 00                	mov    (%eax),%eax
801011e9:	83 f8 02             	cmp    $0x2,%eax
801011ec:	0f 85 de 00 00 00    	jne    801012d0 <filewrite+0x133>
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
801011f2:	c7 45 ec 00 06 00 00 	movl   $0x600,-0x14(%ebp)
    int i = 0;
801011f9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while(i < n){
80101200:	e9 a8 00 00 00       	jmp    801012ad <filewrite+0x110>
      int n1 = n - i;
80101205:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101208:	8b 55 10             	mov    0x10(%ebp),%edx
8010120b:	89 d1                	mov    %edx,%ecx
8010120d:	29 c1                	sub    %eax,%ecx
8010120f:	89 c8                	mov    %ecx,%eax
80101211:	89 45 f0             	mov    %eax,-0x10(%ebp)
      if(n1 > max)
80101214:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101217:	3b 45 ec             	cmp    -0x14(%ebp),%eax
8010121a:	7e 06                	jle    80101222 <filewrite+0x85>
        n1 = max;
8010121c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010121f:	89 45 f0             	mov    %eax,-0x10(%ebp)

      begin_trans();
80101222:	e8 ee 1f 00 00       	call   80103215 <begin_trans>
      ilock(f->ip);
80101227:	8b 45 08             	mov    0x8(%ebp),%eax
8010122a:	8b 40 10             	mov    0x10(%eax),%eax
8010122d:	89 04 24             	mov    %eax,(%esp)
80101230:	e8 2b 06 00 00       	call   80101860 <ilock>
      if ((r = writei(f->ip, addr + i, f->off, n1)) > 0)
80101235:	8b 5d f0             	mov    -0x10(%ebp),%ebx
80101238:	8b 45 08             	mov    0x8(%ebp),%eax
8010123b:	8b 48 14             	mov    0x14(%eax),%ecx
8010123e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101241:	89 c2                	mov    %eax,%edx
80101243:	03 55 0c             	add    0xc(%ebp),%edx
80101246:	8b 45 08             	mov    0x8(%ebp),%eax
80101249:	8b 40 10             	mov    0x10(%eax),%eax
8010124c:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
80101250:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80101254:	89 54 24 04          	mov    %edx,0x4(%esp)
80101258:	89 04 24             	mov    %eax,(%esp)
8010125b:	e8 61 0c 00 00       	call   80101ec1 <writei>
80101260:	89 45 e8             	mov    %eax,-0x18(%ebp)
80101263:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80101267:	7e 11                	jle    8010127a <filewrite+0xdd>
        f->off += r;
80101269:	8b 45 08             	mov    0x8(%ebp),%eax
8010126c:	8b 50 14             	mov    0x14(%eax),%edx
8010126f:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101272:	01 c2                	add    %eax,%edx
80101274:	8b 45 08             	mov    0x8(%ebp),%eax
80101277:	89 50 14             	mov    %edx,0x14(%eax)
      iunlock(f->ip);
8010127a:	8b 45 08             	mov    0x8(%ebp),%eax
8010127d:	8b 40 10             	mov    0x10(%eax),%eax
80101280:	89 04 24             	mov    %eax,(%esp)
80101283:	e8 26 07 00 00       	call   801019ae <iunlock>
      commit_trans();
80101288:	e8 d1 1f 00 00       	call   8010325e <commit_trans>

      if(r < 0)
8010128d:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80101291:	78 28                	js     801012bb <filewrite+0x11e>
        break;
      if(r != n1)
80101293:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101296:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80101299:	74 0c                	je     801012a7 <filewrite+0x10a>
        panic("short filewrite");
8010129b:	c7 04 24 f7 80 10 80 	movl   $0x801080f7,(%esp)
801012a2:	e8 96 f2 ff ff       	call   8010053d <panic>
      i += r;
801012a7:	8b 45 e8             	mov    -0x18(%ebp),%eax
801012aa:	01 45 f4             	add    %eax,-0xc(%ebp)
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
    int i = 0;
    while(i < n){
801012ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801012b0:	3b 45 10             	cmp    0x10(%ebp),%eax
801012b3:	0f 8c 4c ff ff ff    	jl     80101205 <filewrite+0x68>
801012b9:	eb 01                	jmp    801012bc <filewrite+0x11f>
        f->off += r;
      iunlock(f->ip);
      commit_trans();

      if(r < 0)
        break;
801012bb:	90                   	nop
      if(r != n1)
        panic("short filewrite");
      i += r;
    }
    return i == n ? n : -1;
801012bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801012bf:	3b 45 10             	cmp    0x10(%ebp),%eax
801012c2:	75 05                	jne    801012c9 <filewrite+0x12c>
801012c4:	8b 45 10             	mov    0x10(%ebp),%eax
801012c7:	eb 05                	jmp    801012ce <filewrite+0x131>
801012c9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801012ce:	eb 0c                	jmp    801012dc <filewrite+0x13f>
  }
  panic("filewrite");
801012d0:	c7 04 24 07 81 10 80 	movl   $0x80108107,(%esp)
801012d7:	e8 61 f2 ff ff       	call   8010053d <panic>
}
801012dc:	83 c4 24             	add    $0x24,%esp
801012df:	5b                   	pop    %ebx
801012e0:	5d                   	pop    %ebp
801012e1:	c3                   	ret    
	...

801012e4 <readsb>:
static void itrunc(struct inode*);

// Read the super block.
void
readsb(int dev, struct superblock *sb)
{
801012e4:	55                   	push   %ebp
801012e5:	89 e5                	mov    %esp,%ebp
801012e7:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, 1);
801012ea:	8b 45 08             	mov    0x8(%ebp),%eax
801012ed:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801012f4:	00 
801012f5:	89 04 24             	mov    %eax,(%esp)
801012f8:	e8 a9 ee ff ff       	call   801001a6 <bread>
801012fd:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memmove(sb, bp->data, sizeof(*sb));
80101300:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101303:	83 c0 18             	add    $0x18,%eax
80101306:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
8010130d:	00 
8010130e:	89 44 24 04          	mov    %eax,0x4(%esp)
80101312:	8b 45 0c             	mov    0xc(%ebp),%eax
80101315:	89 04 24             	mov    %eax,(%esp)
80101318:	e8 c8 3a 00 00       	call   80104de5 <memmove>
  brelse(bp);
8010131d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101320:	89 04 24             	mov    %eax,(%esp)
80101323:	e8 ef ee ff ff       	call   80100217 <brelse>
}
80101328:	c9                   	leave  
80101329:	c3                   	ret    

8010132a <bzero>:

// Zero a block.
static void
bzero(int dev, int bno)
{
8010132a:	55                   	push   %ebp
8010132b:	89 e5                	mov    %esp,%ebp
8010132d:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, bno);
80101330:	8b 55 0c             	mov    0xc(%ebp),%edx
80101333:	8b 45 08             	mov    0x8(%ebp),%eax
80101336:	89 54 24 04          	mov    %edx,0x4(%esp)
8010133a:	89 04 24             	mov    %eax,(%esp)
8010133d:	e8 64 ee ff ff       	call   801001a6 <bread>
80101342:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(bp->data, 0, BSIZE);
80101345:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101348:	83 c0 18             	add    $0x18,%eax
8010134b:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80101352:	00 
80101353:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010135a:	00 
8010135b:	89 04 24             	mov    %eax,(%esp)
8010135e:	e8 af 39 00 00       	call   80104d12 <memset>
  log_write(bp);
80101363:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101366:	89 04 24             	mov    %eax,(%esp)
80101369:	e8 48 1f 00 00       	call   801032b6 <log_write>
  brelse(bp);
8010136e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101371:	89 04 24             	mov    %eax,(%esp)
80101374:	e8 9e ee ff ff       	call   80100217 <brelse>
}
80101379:	c9                   	leave  
8010137a:	c3                   	ret    

8010137b <balloc>:
// Blocks. 

// Allocate a zeroed disk block.
static uint
balloc(uint dev)
{
8010137b:	55                   	push   %ebp
8010137c:	89 e5                	mov    %esp,%ebp
8010137e:	53                   	push   %ebx
8010137f:	83 ec 34             	sub    $0x34,%esp
  int b, bi, m;
  struct buf *bp;
  struct superblock sb;

  bp = 0;
80101382:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  readsb(dev, &sb);
80101389:	8b 45 08             	mov    0x8(%ebp),%eax
8010138c:	8d 55 d8             	lea    -0x28(%ebp),%edx
8010138f:	89 54 24 04          	mov    %edx,0x4(%esp)
80101393:	89 04 24             	mov    %eax,(%esp)
80101396:	e8 49 ff ff ff       	call   801012e4 <readsb>
  for(b = 0; b < sb.size; b += BPB){
8010139b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801013a2:	e9 11 01 00 00       	jmp    801014b8 <balloc+0x13d>
    bp = bread(dev, BBLOCK(b, sb.ninodes));
801013a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013aa:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
801013b0:	85 c0                	test   %eax,%eax
801013b2:	0f 48 c2             	cmovs  %edx,%eax
801013b5:	c1 f8 0c             	sar    $0xc,%eax
801013b8:	8b 55 e0             	mov    -0x20(%ebp),%edx
801013bb:	c1 ea 03             	shr    $0x3,%edx
801013be:	01 d0                	add    %edx,%eax
801013c0:	83 c0 03             	add    $0x3,%eax
801013c3:	89 44 24 04          	mov    %eax,0x4(%esp)
801013c7:	8b 45 08             	mov    0x8(%ebp),%eax
801013ca:	89 04 24             	mov    %eax,(%esp)
801013cd:	e8 d4 ed ff ff       	call   801001a6 <bread>
801013d2:	89 45 ec             	mov    %eax,-0x14(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
801013d5:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
801013dc:	e9 a7 00 00 00       	jmp    80101488 <balloc+0x10d>
      m = 1 << (bi % 8);
801013e1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801013e4:	89 c2                	mov    %eax,%edx
801013e6:	c1 fa 1f             	sar    $0x1f,%edx
801013e9:	c1 ea 1d             	shr    $0x1d,%edx
801013ec:	01 d0                	add    %edx,%eax
801013ee:	83 e0 07             	and    $0x7,%eax
801013f1:	29 d0                	sub    %edx,%eax
801013f3:	ba 01 00 00 00       	mov    $0x1,%edx
801013f8:	89 d3                	mov    %edx,%ebx
801013fa:	89 c1                	mov    %eax,%ecx
801013fc:	d3 e3                	shl    %cl,%ebx
801013fe:	89 d8                	mov    %ebx,%eax
80101400:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if((bp->data[bi/8] & m) == 0){  // Is block free?
80101403:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101406:	8d 50 07             	lea    0x7(%eax),%edx
80101409:	85 c0                	test   %eax,%eax
8010140b:	0f 48 c2             	cmovs  %edx,%eax
8010140e:	c1 f8 03             	sar    $0x3,%eax
80101411:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101414:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
80101419:	0f b6 c0             	movzbl %al,%eax
8010141c:	23 45 e8             	and    -0x18(%ebp),%eax
8010141f:	85 c0                	test   %eax,%eax
80101421:	75 61                	jne    80101484 <balloc+0x109>
        bp->data[bi/8] |= m;  // Mark block in use.
80101423:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101426:	8d 50 07             	lea    0x7(%eax),%edx
80101429:	85 c0                	test   %eax,%eax
8010142b:	0f 48 c2             	cmovs  %edx,%eax
8010142e:	c1 f8 03             	sar    $0x3,%eax
80101431:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101434:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
80101439:	89 d1                	mov    %edx,%ecx
8010143b:	8b 55 e8             	mov    -0x18(%ebp),%edx
8010143e:	09 ca                	or     %ecx,%edx
80101440:	89 d1                	mov    %edx,%ecx
80101442:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101445:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
        log_write(bp);
80101449:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010144c:	89 04 24             	mov    %eax,(%esp)
8010144f:	e8 62 1e 00 00       	call   801032b6 <log_write>
        brelse(bp);
80101454:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101457:	89 04 24             	mov    %eax,(%esp)
8010145a:	e8 b8 ed ff ff       	call   80100217 <brelse>
        bzero(dev, b + bi);
8010145f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101462:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101465:	01 c2                	add    %eax,%edx
80101467:	8b 45 08             	mov    0x8(%ebp),%eax
8010146a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010146e:	89 04 24             	mov    %eax,(%esp)
80101471:	e8 b4 fe ff ff       	call   8010132a <bzero>
        return b + bi;
80101476:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101479:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010147c:	01 d0                	add    %edx,%eax
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
}
8010147e:	83 c4 34             	add    $0x34,%esp
80101481:	5b                   	pop    %ebx
80101482:	5d                   	pop    %ebp
80101483:	c3                   	ret    

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
    bp = bread(dev, BBLOCK(b, sb.ninodes));
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
80101484:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80101488:	81 7d f0 ff 0f 00 00 	cmpl   $0xfff,-0x10(%ebp)
8010148f:	7f 15                	jg     801014a6 <balloc+0x12b>
80101491:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101494:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101497:	01 d0                	add    %edx,%eax
80101499:	89 c2                	mov    %eax,%edx
8010149b:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010149e:	39 c2                	cmp    %eax,%edx
801014a0:	0f 82 3b ff ff ff    	jb     801013e1 <balloc+0x66>
        brelse(bp);
        bzero(dev, b + bi);
        return b + bi;
      }
    }
    brelse(bp);
801014a6:	8b 45 ec             	mov    -0x14(%ebp),%eax
801014a9:	89 04 24             	mov    %eax,(%esp)
801014ac:	e8 66 ed ff ff       	call   80100217 <brelse>
  struct buf *bp;
  struct superblock sb;

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
801014b1:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801014b8:	8b 55 f4             	mov    -0xc(%ebp),%edx
801014bb:	8b 45 d8             	mov    -0x28(%ebp),%eax
801014be:	39 c2                	cmp    %eax,%edx
801014c0:	0f 82 e1 fe ff ff    	jb     801013a7 <balloc+0x2c>
        return b + bi;
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
801014c6:	c7 04 24 11 81 10 80 	movl   $0x80108111,(%esp)
801014cd:	e8 6b f0 ff ff       	call   8010053d <panic>

801014d2 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
801014d2:	55                   	push   %ebp
801014d3:	89 e5                	mov    %esp,%ebp
801014d5:	53                   	push   %ebx
801014d6:	83 ec 34             	sub    $0x34,%esp
  struct buf *bp;
  struct superblock sb;
  int bi, m;

  readsb(dev, &sb);
801014d9:	8d 45 dc             	lea    -0x24(%ebp),%eax
801014dc:	89 44 24 04          	mov    %eax,0x4(%esp)
801014e0:	8b 45 08             	mov    0x8(%ebp),%eax
801014e3:	89 04 24             	mov    %eax,(%esp)
801014e6:	e8 f9 fd ff ff       	call   801012e4 <readsb>
  bp = bread(dev, BBLOCK(b, sb.ninodes));
801014eb:	8b 45 0c             	mov    0xc(%ebp),%eax
801014ee:	89 c2                	mov    %eax,%edx
801014f0:	c1 ea 0c             	shr    $0xc,%edx
801014f3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801014f6:	c1 e8 03             	shr    $0x3,%eax
801014f9:	01 d0                	add    %edx,%eax
801014fb:	8d 50 03             	lea    0x3(%eax),%edx
801014fe:	8b 45 08             	mov    0x8(%ebp),%eax
80101501:	89 54 24 04          	mov    %edx,0x4(%esp)
80101505:	89 04 24             	mov    %eax,(%esp)
80101508:	e8 99 ec ff ff       	call   801001a6 <bread>
8010150d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  bi = b % BPB;
80101510:	8b 45 0c             	mov    0xc(%ebp),%eax
80101513:	25 ff 0f 00 00       	and    $0xfff,%eax
80101518:	89 45 f0             	mov    %eax,-0x10(%ebp)
  m = 1 << (bi % 8);
8010151b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010151e:	89 c2                	mov    %eax,%edx
80101520:	c1 fa 1f             	sar    $0x1f,%edx
80101523:	c1 ea 1d             	shr    $0x1d,%edx
80101526:	01 d0                	add    %edx,%eax
80101528:	83 e0 07             	and    $0x7,%eax
8010152b:	29 d0                	sub    %edx,%eax
8010152d:	ba 01 00 00 00       	mov    $0x1,%edx
80101532:	89 d3                	mov    %edx,%ebx
80101534:	89 c1                	mov    %eax,%ecx
80101536:	d3 e3                	shl    %cl,%ebx
80101538:	89 d8                	mov    %ebx,%eax
8010153a:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((bp->data[bi/8] & m) == 0)
8010153d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101540:	8d 50 07             	lea    0x7(%eax),%edx
80101543:	85 c0                	test   %eax,%eax
80101545:	0f 48 c2             	cmovs  %edx,%eax
80101548:	c1 f8 03             	sar    $0x3,%eax
8010154b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010154e:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
80101553:	0f b6 c0             	movzbl %al,%eax
80101556:	23 45 ec             	and    -0x14(%ebp),%eax
80101559:	85 c0                	test   %eax,%eax
8010155b:	75 0c                	jne    80101569 <bfree+0x97>
    panic("freeing free block");
8010155d:	c7 04 24 27 81 10 80 	movl   $0x80108127,(%esp)
80101564:	e8 d4 ef ff ff       	call   8010053d <panic>
  bp->data[bi/8] &= ~m;
80101569:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010156c:	8d 50 07             	lea    0x7(%eax),%edx
8010156f:	85 c0                	test   %eax,%eax
80101571:	0f 48 c2             	cmovs  %edx,%eax
80101574:	c1 f8 03             	sar    $0x3,%eax
80101577:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010157a:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
8010157f:	8b 4d ec             	mov    -0x14(%ebp),%ecx
80101582:	f7 d1                	not    %ecx
80101584:	21 ca                	and    %ecx,%edx
80101586:	89 d1                	mov    %edx,%ecx
80101588:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010158b:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
  log_write(bp);
8010158f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101592:	89 04 24             	mov    %eax,(%esp)
80101595:	e8 1c 1d 00 00       	call   801032b6 <log_write>
  brelse(bp);
8010159a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010159d:	89 04 24             	mov    %eax,(%esp)
801015a0:	e8 72 ec ff ff       	call   80100217 <brelse>
}
801015a5:	83 c4 34             	add    $0x34,%esp
801015a8:	5b                   	pop    %ebx
801015a9:	5d                   	pop    %ebp
801015aa:	c3                   	ret    

801015ab <iinit>:
  struct inode inode[NINODE];
} icache;

void
iinit(void)
{
801015ab:	55                   	push   %ebp
801015ac:	89 e5                	mov    %esp,%ebp
801015ae:	83 ec 18             	sub    $0x18,%esp
  initlock(&icache.lock, "icache");
801015b1:	c7 44 24 04 3a 81 10 	movl   $0x8010813a,0x4(%esp)
801015b8:	80 
801015b9:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
801015c0:	e8 dd 34 00 00       	call   80104aa2 <initlock>
}
801015c5:	c9                   	leave  
801015c6:	c3                   	ret    

801015c7 <ialloc>:
//PAGEBREAK!
// Allocate a new inode with the given type on device dev.
// A free inode has a type of zero.
struct inode*
ialloc(uint dev, short type)
{
801015c7:	55                   	push   %ebp
801015c8:	89 e5                	mov    %esp,%ebp
801015ca:	83 ec 48             	sub    $0x48,%esp
801015cd:	8b 45 0c             	mov    0xc(%ebp),%eax
801015d0:	66 89 45 d4          	mov    %ax,-0x2c(%ebp)
  int inum;
  struct buf *bp;
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);
801015d4:	8b 45 08             	mov    0x8(%ebp),%eax
801015d7:	8d 55 dc             	lea    -0x24(%ebp),%edx
801015da:	89 54 24 04          	mov    %edx,0x4(%esp)
801015de:	89 04 24             	mov    %eax,(%esp)
801015e1:	e8 fe fc ff ff       	call   801012e4 <readsb>

  for(inum = 1; inum < sb.ninodes; inum++){
801015e6:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
801015ed:	e9 98 00 00 00       	jmp    8010168a <ialloc+0xc3>
    bp = bread(dev, IBLOCK(inum));
801015f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801015f5:	c1 e8 03             	shr    $0x3,%eax
801015f8:	83 c0 02             	add    $0x2,%eax
801015fb:	89 44 24 04          	mov    %eax,0x4(%esp)
801015ff:	8b 45 08             	mov    0x8(%ebp),%eax
80101602:	89 04 24             	mov    %eax,(%esp)
80101605:	e8 9c eb ff ff       	call   801001a6 <bread>
8010160a:	89 45 f0             	mov    %eax,-0x10(%ebp)
    dip = (struct dinode*)bp->data + inum%IPB;
8010160d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101610:	8d 50 18             	lea    0x18(%eax),%edx
80101613:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101616:	83 e0 07             	and    $0x7,%eax
80101619:	c1 e0 06             	shl    $0x6,%eax
8010161c:	01 d0                	add    %edx,%eax
8010161e:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(dip->type == 0){  // a free inode
80101621:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101624:	0f b7 00             	movzwl (%eax),%eax
80101627:	66 85 c0             	test   %ax,%ax
8010162a:	75 4f                	jne    8010167b <ialloc+0xb4>
      memset(dip, 0, sizeof(*dip));
8010162c:	c7 44 24 08 40 00 00 	movl   $0x40,0x8(%esp)
80101633:	00 
80101634:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010163b:	00 
8010163c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010163f:	89 04 24             	mov    %eax,(%esp)
80101642:	e8 cb 36 00 00       	call   80104d12 <memset>
      dip->type = type;
80101647:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010164a:	0f b7 55 d4          	movzwl -0x2c(%ebp),%edx
8010164e:	66 89 10             	mov    %dx,(%eax)
      log_write(bp);   // mark it allocated on the disk
80101651:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101654:	89 04 24             	mov    %eax,(%esp)
80101657:	e8 5a 1c 00 00       	call   801032b6 <log_write>
      brelse(bp);
8010165c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010165f:	89 04 24             	mov    %eax,(%esp)
80101662:	e8 b0 eb ff ff       	call   80100217 <brelse>
      return iget(dev, inum);
80101667:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010166a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010166e:	8b 45 08             	mov    0x8(%ebp),%eax
80101671:	89 04 24             	mov    %eax,(%esp)
80101674:	e8 e3 00 00 00       	call   8010175c <iget>
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
}
80101679:	c9                   	leave  
8010167a:	c3                   	ret    
      dip->type = type;
      log_write(bp);   // mark it allocated on the disk
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
8010167b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010167e:	89 04 24             	mov    %eax,(%esp)
80101681:	e8 91 eb ff ff       	call   80100217 <brelse>
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);

  for(inum = 1; inum < sb.ninodes; inum++){
80101686:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010168a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010168d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101690:	39 c2                	cmp    %eax,%edx
80101692:	0f 82 5a ff ff ff    	jb     801015f2 <ialloc+0x2b>
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
80101698:	c7 04 24 41 81 10 80 	movl   $0x80108141,(%esp)
8010169f:	e8 99 ee ff ff       	call   8010053d <panic>

801016a4 <iupdate>:
}

// Copy a modified in-memory inode to disk.
void
iupdate(struct inode *ip)
{
801016a4:	55                   	push   %ebp
801016a5:	89 e5                	mov    %esp,%ebp
801016a7:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  bp = bread(ip->dev, IBLOCK(ip->inum));
801016aa:	8b 45 08             	mov    0x8(%ebp),%eax
801016ad:	8b 40 04             	mov    0x4(%eax),%eax
801016b0:	c1 e8 03             	shr    $0x3,%eax
801016b3:	8d 50 02             	lea    0x2(%eax),%edx
801016b6:	8b 45 08             	mov    0x8(%ebp),%eax
801016b9:	8b 00                	mov    (%eax),%eax
801016bb:	89 54 24 04          	mov    %edx,0x4(%esp)
801016bf:	89 04 24             	mov    %eax,(%esp)
801016c2:	e8 df ea ff ff       	call   801001a6 <bread>
801016c7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  dip = (struct dinode*)bp->data + ip->inum%IPB;
801016ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
801016cd:	8d 50 18             	lea    0x18(%eax),%edx
801016d0:	8b 45 08             	mov    0x8(%ebp),%eax
801016d3:	8b 40 04             	mov    0x4(%eax),%eax
801016d6:	83 e0 07             	and    $0x7,%eax
801016d9:	c1 e0 06             	shl    $0x6,%eax
801016dc:	01 d0                	add    %edx,%eax
801016de:	89 45 f0             	mov    %eax,-0x10(%ebp)
  dip->type = ip->type;
801016e1:	8b 45 08             	mov    0x8(%ebp),%eax
801016e4:	0f b7 50 10          	movzwl 0x10(%eax),%edx
801016e8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801016eb:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
801016ee:	8b 45 08             	mov    0x8(%ebp),%eax
801016f1:	0f b7 50 12          	movzwl 0x12(%eax),%edx
801016f5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801016f8:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
801016fc:	8b 45 08             	mov    0x8(%ebp),%eax
801016ff:	0f b7 50 14          	movzwl 0x14(%eax),%edx
80101703:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101706:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
8010170a:	8b 45 08             	mov    0x8(%ebp),%eax
8010170d:	0f b7 50 16          	movzwl 0x16(%eax),%edx
80101711:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101714:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
80101718:	8b 45 08             	mov    0x8(%ebp),%eax
8010171b:	8b 50 18             	mov    0x18(%eax),%edx
8010171e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101721:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
80101724:	8b 45 08             	mov    0x8(%ebp),%eax
80101727:	8d 50 1c             	lea    0x1c(%eax),%edx
8010172a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010172d:	83 c0 0c             	add    $0xc,%eax
80101730:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
80101737:	00 
80101738:	89 54 24 04          	mov    %edx,0x4(%esp)
8010173c:	89 04 24             	mov    %eax,(%esp)
8010173f:	e8 a1 36 00 00       	call   80104de5 <memmove>
  log_write(bp);
80101744:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101747:	89 04 24             	mov    %eax,(%esp)
8010174a:	e8 67 1b 00 00       	call   801032b6 <log_write>
  brelse(bp);
8010174f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101752:	89 04 24             	mov    %eax,(%esp)
80101755:	e8 bd ea ff ff       	call   80100217 <brelse>
}
8010175a:	c9                   	leave  
8010175b:	c3                   	ret    

8010175c <iget>:
// Find the inode with number inum on device dev
// and return the in-memory copy. Does not lock
// the inode and does not read it from disk.
static struct inode*
iget(uint dev, uint inum)
{
8010175c:	55                   	push   %ebp
8010175d:	89 e5                	mov    %esp,%ebp
8010175f:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *empty;

  acquire(&icache.lock);
80101762:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
80101769:	e8 55 33 00 00       	call   80104ac3 <acquire>

  // Is the inode already cached?
  empty = 0;
8010176e:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
80101775:	c7 45 f4 94 e8 10 80 	movl   $0x8010e894,-0xc(%ebp)
8010177c:	eb 59                	jmp    801017d7 <iget+0x7b>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
8010177e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101781:	8b 40 08             	mov    0x8(%eax),%eax
80101784:	85 c0                	test   %eax,%eax
80101786:	7e 35                	jle    801017bd <iget+0x61>
80101788:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010178b:	8b 00                	mov    (%eax),%eax
8010178d:	3b 45 08             	cmp    0x8(%ebp),%eax
80101790:	75 2b                	jne    801017bd <iget+0x61>
80101792:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101795:	8b 40 04             	mov    0x4(%eax),%eax
80101798:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010179b:	75 20                	jne    801017bd <iget+0x61>
      ip->ref++;
8010179d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017a0:	8b 40 08             	mov    0x8(%eax),%eax
801017a3:	8d 50 01             	lea    0x1(%eax),%edx
801017a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017a9:	89 50 08             	mov    %edx,0x8(%eax)
      release(&icache.lock);
801017ac:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
801017b3:	e8 6d 33 00 00       	call   80104b25 <release>
      return ip;
801017b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017bb:	eb 6f                	jmp    8010182c <iget+0xd0>
    }
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
801017bd:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801017c1:	75 10                	jne    801017d3 <iget+0x77>
801017c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017c6:	8b 40 08             	mov    0x8(%eax),%eax
801017c9:	85 c0                	test   %eax,%eax
801017cb:	75 06                	jne    801017d3 <iget+0x77>
      empty = ip;
801017cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017d0:	89 45 f0             	mov    %eax,-0x10(%ebp)

  acquire(&icache.lock);

  // Is the inode already cached?
  empty = 0;
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801017d3:	83 45 f4 50          	addl   $0x50,-0xc(%ebp)
801017d7:	81 7d f4 34 f8 10 80 	cmpl   $0x8010f834,-0xc(%ebp)
801017de:	72 9e                	jb     8010177e <iget+0x22>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
      empty = ip;
  }

  // Recycle an inode cache entry.
  if(empty == 0)
801017e0:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801017e4:	75 0c                	jne    801017f2 <iget+0x96>
    panic("iget: no inodes");
801017e6:	c7 04 24 53 81 10 80 	movl   $0x80108153,(%esp)
801017ed:	e8 4b ed ff ff       	call   8010053d <panic>

  ip = empty;
801017f2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801017f5:	89 45 f4             	mov    %eax,-0xc(%ebp)
  ip->dev = dev;
801017f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017fb:	8b 55 08             	mov    0x8(%ebp),%edx
801017fe:	89 10                	mov    %edx,(%eax)
  ip->inum = inum;
80101800:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101803:	8b 55 0c             	mov    0xc(%ebp),%edx
80101806:	89 50 04             	mov    %edx,0x4(%eax)
  ip->ref = 1;
80101809:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010180c:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)
  ip->flags = 0;
80101813:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101816:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  release(&icache.lock);
8010181d:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
80101824:	e8 fc 32 00 00       	call   80104b25 <release>

  return ip;
80101829:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010182c:	c9                   	leave  
8010182d:	c3                   	ret    

8010182e <idup>:

// Increment reference count for ip.
// Returns ip to enable ip = idup(ip1) idiom.
struct inode*
idup(struct inode *ip)
{
8010182e:	55                   	push   %ebp
8010182f:	89 e5                	mov    %esp,%ebp
80101831:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
80101834:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
8010183b:	e8 83 32 00 00       	call   80104ac3 <acquire>
  ip->ref++;
80101840:	8b 45 08             	mov    0x8(%ebp),%eax
80101843:	8b 40 08             	mov    0x8(%eax),%eax
80101846:	8d 50 01             	lea    0x1(%eax),%edx
80101849:	8b 45 08             	mov    0x8(%ebp),%eax
8010184c:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
8010184f:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
80101856:	e8 ca 32 00 00       	call   80104b25 <release>
  return ip;
8010185b:	8b 45 08             	mov    0x8(%ebp),%eax
}
8010185e:	c9                   	leave  
8010185f:	c3                   	ret    

80101860 <ilock>:

// Lock the given inode.
// Reads the inode from disk if necessary.
void
ilock(struct inode *ip)
{
80101860:	55                   	push   %ebp
80101861:	89 e5                	mov    %esp,%ebp
80101863:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  if(ip == 0 || ip->ref < 1)
80101866:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010186a:	74 0a                	je     80101876 <ilock+0x16>
8010186c:	8b 45 08             	mov    0x8(%ebp),%eax
8010186f:	8b 40 08             	mov    0x8(%eax),%eax
80101872:	85 c0                	test   %eax,%eax
80101874:	7f 0c                	jg     80101882 <ilock+0x22>
    panic("ilock");
80101876:	c7 04 24 63 81 10 80 	movl   $0x80108163,(%esp)
8010187d:	e8 bb ec ff ff       	call   8010053d <panic>

  acquire(&icache.lock);
80101882:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
80101889:	e8 35 32 00 00       	call   80104ac3 <acquire>
  while(ip->flags & I_BUSY)
8010188e:	eb 13                	jmp    801018a3 <ilock+0x43>
    sleep(ip, &icache.lock);
80101890:	c7 44 24 04 60 e8 10 	movl   $0x8010e860,0x4(%esp)
80101897:	80 
80101898:	8b 45 08             	mov    0x8(%ebp),%eax
8010189b:	89 04 24             	mov    %eax,(%esp)
8010189e:	e8 44 2f 00 00       	call   801047e7 <sleep>

  if(ip == 0 || ip->ref < 1)
    panic("ilock");

  acquire(&icache.lock);
  while(ip->flags & I_BUSY)
801018a3:	8b 45 08             	mov    0x8(%ebp),%eax
801018a6:	8b 40 0c             	mov    0xc(%eax),%eax
801018a9:	83 e0 01             	and    $0x1,%eax
801018ac:	84 c0                	test   %al,%al
801018ae:	75 e0                	jne    80101890 <ilock+0x30>
    sleep(ip, &icache.lock);
  ip->flags |= I_BUSY;
801018b0:	8b 45 08             	mov    0x8(%ebp),%eax
801018b3:	8b 40 0c             	mov    0xc(%eax),%eax
801018b6:	89 c2                	mov    %eax,%edx
801018b8:	83 ca 01             	or     $0x1,%edx
801018bb:	8b 45 08             	mov    0x8(%ebp),%eax
801018be:	89 50 0c             	mov    %edx,0xc(%eax)
  release(&icache.lock);
801018c1:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
801018c8:	e8 58 32 00 00       	call   80104b25 <release>

  if(!(ip->flags & I_VALID)){
801018cd:	8b 45 08             	mov    0x8(%ebp),%eax
801018d0:	8b 40 0c             	mov    0xc(%eax),%eax
801018d3:	83 e0 02             	and    $0x2,%eax
801018d6:	85 c0                	test   %eax,%eax
801018d8:	0f 85 ce 00 00 00    	jne    801019ac <ilock+0x14c>
    bp = bread(ip->dev, IBLOCK(ip->inum));
801018de:	8b 45 08             	mov    0x8(%ebp),%eax
801018e1:	8b 40 04             	mov    0x4(%eax),%eax
801018e4:	c1 e8 03             	shr    $0x3,%eax
801018e7:	8d 50 02             	lea    0x2(%eax),%edx
801018ea:	8b 45 08             	mov    0x8(%ebp),%eax
801018ed:	8b 00                	mov    (%eax),%eax
801018ef:	89 54 24 04          	mov    %edx,0x4(%esp)
801018f3:	89 04 24             	mov    %eax,(%esp)
801018f6:	e8 ab e8 ff ff       	call   801001a6 <bread>
801018fb:	89 45 f4             	mov    %eax,-0xc(%ebp)
    dip = (struct dinode*)bp->data + ip->inum%IPB;
801018fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101901:	8d 50 18             	lea    0x18(%eax),%edx
80101904:	8b 45 08             	mov    0x8(%ebp),%eax
80101907:	8b 40 04             	mov    0x4(%eax),%eax
8010190a:	83 e0 07             	and    $0x7,%eax
8010190d:	c1 e0 06             	shl    $0x6,%eax
80101910:	01 d0                	add    %edx,%eax
80101912:	89 45 f0             	mov    %eax,-0x10(%ebp)
    ip->type = dip->type;
80101915:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101918:	0f b7 10             	movzwl (%eax),%edx
8010191b:	8b 45 08             	mov    0x8(%ebp),%eax
8010191e:	66 89 50 10          	mov    %dx,0x10(%eax)
    ip->major = dip->major;
80101922:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101925:	0f b7 50 02          	movzwl 0x2(%eax),%edx
80101929:	8b 45 08             	mov    0x8(%ebp),%eax
8010192c:	66 89 50 12          	mov    %dx,0x12(%eax)
    ip->minor = dip->minor;
80101930:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101933:	0f b7 50 04          	movzwl 0x4(%eax),%edx
80101937:	8b 45 08             	mov    0x8(%ebp),%eax
8010193a:	66 89 50 14          	mov    %dx,0x14(%eax)
    ip->nlink = dip->nlink;
8010193e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101941:	0f b7 50 06          	movzwl 0x6(%eax),%edx
80101945:	8b 45 08             	mov    0x8(%ebp),%eax
80101948:	66 89 50 16          	mov    %dx,0x16(%eax)
    ip->size = dip->size;
8010194c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010194f:	8b 50 08             	mov    0x8(%eax),%edx
80101952:	8b 45 08             	mov    0x8(%ebp),%eax
80101955:	89 50 18             	mov    %edx,0x18(%eax)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
80101958:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010195b:	8d 50 0c             	lea    0xc(%eax),%edx
8010195e:	8b 45 08             	mov    0x8(%ebp),%eax
80101961:	83 c0 1c             	add    $0x1c,%eax
80101964:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
8010196b:	00 
8010196c:	89 54 24 04          	mov    %edx,0x4(%esp)
80101970:	89 04 24             	mov    %eax,(%esp)
80101973:	e8 6d 34 00 00       	call   80104de5 <memmove>
    brelse(bp);
80101978:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010197b:	89 04 24             	mov    %eax,(%esp)
8010197e:	e8 94 e8 ff ff       	call   80100217 <brelse>
    ip->flags |= I_VALID;
80101983:	8b 45 08             	mov    0x8(%ebp),%eax
80101986:	8b 40 0c             	mov    0xc(%eax),%eax
80101989:	89 c2                	mov    %eax,%edx
8010198b:	83 ca 02             	or     $0x2,%edx
8010198e:	8b 45 08             	mov    0x8(%ebp),%eax
80101991:	89 50 0c             	mov    %edx,0xc(%eax)
    if(ip->type == 0)
80101994:	8b 45 08             	mov    0x8(%ebp),%eax
80101997:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010199b:	66 85 c0             	test   %ax,%ax
8010199e:	75 0c                	jne    801019ac <ilock+0x14c>
      panic("ilock: no type");
801019a0:	c7 04 24 69 81 10 80 	movl   $0x80108169,(%esp)
801019a7:	e8 91 eb ff ff       	call   8010053d <panic>
  }
}
801019ac:	c9                   	leave  
801019ad:	c3                   	ret    

801019ae <iunlock>:

// Unlock the given inode.
void
iunlock(struct inode *ip)
{
801019ae:	55                   	push   %ebp
801019af:	89 e5                	mov    %esp,%ebp
801019b1:	83 ec 18             	sub    $0x18,%esp
  if(ip == 0 || !(ip->flags & I_BUSY) || ip->ref < 1)
801019b4:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801019b8:	74 17                	je     801019d1 <iunlock+0x23>
801019ba:	8b 45 08             	mov    0x8(%ebp),%eax
801019bd:	8b 40 0c             	mov    0xc(%eax),%eax
801019c0:	83 e0 01             	and    $0x1,%eax
801019c3:	85 c0                	test   %eax,%eax
801019c5:	74 0a                	je     801019d1 <iunlock+0x23>
801019c7:	8b 45 08             	mov    0x8(%ebp),%eax
801019ca:	8b 40 08             	mov    0x8(%eax),%eax
801019cd:	85 c0                	test   %eax,%eax
801019cf:	7f 0c                	jg     801019dd <iunlock+0x2f>
    panic("iunlock");
801019d1:	c7 04 24 78 81 10 80 	movl   $0x80108178,(%esp)
801019d8:	e8 60 eb ff ff       	call   8010053d <panic>

  acquire(&icache.lock);
801019dd:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
801019e4:	e8 da 30 00 00       	call   80104ac3 <acquire>
  ip->flags &= ~I_BUSY;
801019e9:	8b 45 08             	mov    0x8(%ebp),%eax
801019ec:	8b 40 0c             	mov    0xc(%eax),%eax
801019ef:	89 c2                	mov    %eax,%edx
801019f1:	83 e2 fe             	and    $0xfffffffe,%edx
801019f4:	8b 45 08             	mov    0x8(%ebp),%eax
801019f7:	89 50 0c             	mov    %edx,0xc(%eax)
  wakeup(ip);
801019fa:	8b 45 08             	mov    0x8(%ebp),%eax
801019fd:	89 04 24             	mov    %eax,(%esp)
80101a00:	e8 bb 2e 00 00       	call   801048c0 <wakeup>
  release(&icache.lock);
80101a05:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
80101a0c:	e8 14 31 00 00       	call   80104b25 <release>
}
80101a11:	c9                   	leave  
80101a12:	c3                   	ret    

80101a13 <iput>:
// be recycled.
// If that was the last reference and the inode has no links
// to it, free the inode (and its content) on disk.
void
iput(struct inode *ip)
{
80101a13:	55                   	push   %ebp
80101a14:	89 e5                	mov    %esp,%ebp
80101a16:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
80101a19:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
80101a20:	e8 9e 30 00 00       	call   80104ac3 <acquire>
  if(ip->ref == 1 && (ip->flags & I_VALID) && ip->nlink == 0){
80101a25:	8b 45 08             	mov    0x8(%ebp),%eax
80101a28:	8b 40 08             	mov    0x8(%eax),%eax
80101a2b:	83 f8 01             	cmp    $0x1,%eax
80101a2e:	0f 85 93 00 00 00    	jne    80101ac7 <iput+0xb4>
80101a34:	8b 45 08             	mov    0x8(%ebp),%eax
80101a37:	8b 40 0c             	mov    0xc(%eax),%eax
80101a3a:	83 e0 02             	and    $0x2,%eax
80101a3d:	85 c0                	test   %eax,%eax
80101a3f:	0f 84 82 00 00 00    	je     80101ac7 <iput+0xb4>
80101a45:	8b 45 08             	mov    0x8(%ebp),%eax
80101a48:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80101a4c:	66 85 c0             	test   %ax,%ax
80101a4f:	75 76                	jne    80101ac7 <iput+0xb4>
    // inode has no links: truncate and free inode.
    if(ip->flags & I_BUSY)
80101a51:	8b 45 08             	mov    0x8(%ebp),%eax
80101a54:	8b 40 0c             	mov    0xc(%eax),%eax
80101a57:	83 e0 01             	and    $0x1,%eax
80101a5a:	84 c0                	test   %al,%al
80101a5c:	74 0c                	je     80101a6a <iput+0x57>
      panic("iput busy");
80101a5e:	c7 04 24 80 81 10 80 	movl   $0x80108180,(%esp)
80101a65:	e8 d3 ea ff ff       	call   8010053d <panic>
    ip->flags |= I_BUSY;
80101a6a:	8b 45 08             	mov    0x8(%ebp),%eax
80101a6d:	8b 40 0c             	mov    0xc(%eax),%eax
80101a70:	89 c2                	mov    %eax,%edx
80101a72:	83 ca 01             	or     $0x1,%edx
80101a75:	8b 45 08             	mov    0x8(%ebp),%eax
80101a78:	89 50 0c             	mov    %edx,0xc(%eax)
    release(&icache.lock);
80101a7b:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
80101a82:	e8 9e 30 00 00       	call   80104b25 <release>
    itrunc(ip);
80101a87:	8b 45 08             	mov    0x8(%ebp),%eax
80101a8a:	89 04 24             	mov    %eax,(%esp)
80101a8d:	e8 72 01 00 00       	call   80101c04 <itrunc>
    ip->type = 0;
80101a92:	8b 45 08             	mov    0x8(%ebp),%eax
80101a95:	66 c7 40 10 00 00    	movw   $0x0,0x10(%eax)
    iupdate(ip);
80101a9b:	8b 45 08             	mov    0x8(%ebp),%eax
80101a9e:	89 04 24             	mov    %eax,(%esp)
80101aa1:	e8 fe fb ff ff       	call   801016a4 <iupdate>
    acquire(&icache.lock);
80101aa6:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
80101aad:	e8 11 30 00 00       	call   80104ac3 <acquire>
    ip->flags = 0;
80101ab2:	8b 45 08             	mov    0x8(%ebp),%eax
80101ab5:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    wakeup(ip);
80101abc:	8b 45 08             	mov    0x8(%ebp),%eax
80101abf:	89 04 24             	mov    %eax,(%esp)
80101ac2:	e8 f9 2d 00 00       	call   801048c0 <wakeup>
  }
  ip->ref--;
80101ac7:	8b 45 08             	mov    0x8(%ebp),%eax
80101aca:	8b 40 08             	mov    0x8(%eax),%eax
80101acd:	8d 50 ff             	lea    -0x1(%eax),%edx
80101ad0:	8b 45 08             	mov    0x8(%ebp),%eax
80101ad3:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101ad6:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
80101add:	e8 43 30 00 00       	call   80104b25 <release>
}
80101ae2:	c9                   	leave  
80101ae3:	c3                   	ret    

80101ae4 <iunlockput>:

// Common idiom: unlock, then put.
void
iunlockput(struct inode *ip)
{
80101ae4:	55                   	push   %ebp
80101ae5:	89 e5                	mov    %esp,%ebp
80101ae7:	83 ec 18             	sub    $0x18,%esp
  iunlock(ip);
80101aea:	8b 45 08             	mov    0x8(%ebp),%eax
80101aed:	89 04 24             	mov    %eax,(%esp)
80101af0:	e8 b9 fe ff ff       	call   801019ae <iunlock>
  iput(ip);
80101af5:	8b 45 08             	mov    0x8(%ebp),%eax
80101af8:	89 04 24             	mov    %eax,(%esp)
80101afb:	e8 13 ff ff ff       	call   80101a13 <iput>
}
80101b00:	c9                   	leave  
80101b01:	c3                   	ret    

80101b02 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
80101b02:	55                   	push   %ebp
80101b03:	89 e5                	mov    %esp,%ebp
80101b05:	53                   	push   %ebx
80101b06:	83 ec 24             	sub    $0x24,%esp
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
80101b09:	83 7d 0c 0b          	cmpl   $0xb,0xc(%ebp)
80101b0d:	77 3e                	ja     80101b4d <bmap+0x4b>
    if((addr = ip->addrs[bn]) == 0)
80101b0f:	8b 45 08             	mov    0x8(%ebp),%eax
80101b12:	8b 55 0c             	mov    0xc(%ebp),%edx
80101b15:	83 c2 04             	add    $0x4,%edx
80101b18:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101b1c:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101b1f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101b23:	75 20                	jne    80101b45 <bmap+0x43>
      ip->addrs[bn] = addr = balloc(ip->dev);
80101b25:	8b 45 08             	mov    0x8(%ebp),%eax
80101b28:	8b 00                	mov    (%eax),%eax
80101b2a:	89 04 24             	mov    %eax,(%esp)
80101b2d:	e8 49 f8 ff ff       	call   8010137b <balloc>
80101b32:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101b35:	8b 45 08             	mov    0x8(%ebp),%eax
80101b38:	8b 55 0c             	mov    0xc(%ebp),%edx
80101b3b:	8d 4a 04             	lea    0x4(%edx),%ecx
80101b3e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101b41:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
    return addr;
80101b45:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101b48:	e9 b1 00 00 00       	jmp    80101bfe <bmap+0xfc>
  }
  bn -= NDIRECT;
80101b4d:	83 6d 0c 0c          	subl   $0xc,0xc(%ebp)

  if(bn < NINDIRECT){
80101b51:	83 7d 0c 7f          	cmpl   $0x7f,0xc(%ebp)
80101b55:	0f 87 97 00 00 00    	ja     80101bf2 <bmap+0xf0>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
80101b5b:	8b 45 08             	mov    0x8(%ebp),%eax
80101b5e:	8b 40 4c             	mov    0x4c(%eax),%eax
80101b61:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101b64:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101b68:	75 19                	jne    80101b83 <bmap+0x81>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
80101b6a:	8b 45 08             	mov    0x8(%ebp),%eax
80101b6d:	8b 00                	mov    (%eax),%eax
80101b6f:	89 04 24             	mov    %eax,(%esp)
80101b72:	e8 04 f8 ff ff       	call   8010137b <balloc>
80101b77:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101b7a:	8b 45 08             	mov    0x8(%ebp),%eax
80101b7d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101b80:	89 50 4c             	mov    %edx,0x4c(%eax)
    bp = bread(ip->dev, addr);
80101b83:	8b 45 08             	mov    0x8(%ebp),%eax
80101b86:	8b 00                	mov    (%eax),%eax
80101b88:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101b8b:	89 54 24 04          	mov    %edx,0x4(%esp)
80101b8f:	89 04 24             	mov    %eax,(%esp)
80101b92:	e8 0f e6 ff ff       	call   801001a6 <bread>
80101b97:	89 45 f0             	mov    %eax,-0x10(%ebp)
    a = (uint*)bp->data;
80101b9a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101b9d:	83 c0 18             	add    $0x18,%eax
80101ba0:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if((addr = a[bn]) == 0){
80101ba3:	8b 45 0c             	mov    0xc(%ebp),%eax
80101ba6:	c1 e0 02             	shl    $0x2,%eax
80101ba9:	03 45 ec             	add    -0x14(%ebp),%eax
80101bac:	8b 00                	mov    (%eax),%eax
80101bae:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101bb1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101bb5:	75 2b                	jne    80101be2 <bmap+0xe0>
      a[bn] = addr = balloc(ip->dev);
80101bb7:	8b 45 0c             	mov    0xc(%ebp),%eax
80101bba:	c1 e0 02             	shl    $0x2,%eax
80101bbd:	89 c3                	mov    %eax,%ebx
80101bbf:	03 5d ec             	add    -0x14(%ebp),%ebx
80101bc2:	8b 45 08             	mov    0x8(%ebp),%eax
80101bc5:	8b 00                	mov    (%eax),%eax
80101bc7:	89 04 24             	mov    %eax,(%esp)
80101bca:	e8 ac f7 ff ff       	call   8010137b <balloc>
80101bcf:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101bd2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101bd5:	89 03                	mov    %eax,(%ebx)
      log_write(bp);
80101bd7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101bda:	89 04 24             	mov    %eax,(%esp)
80101bdd:	e8 d4 16 00 00       	call   801032b6 <log_write>
    }
    brelse(bp);
80101be2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101be5:	89 04 24             	mov    %eax,(%esp)
80101be8:	e8 2a e6 ff ff       	call   80100217 <brelse>
    return addr;
80101bed:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101bf0:	eb 0c                	jmp    80101bfe <bmap+0xfc>
  }

  panic("bmap: out of range");
80101bf2:	c7 04 24 8a 81 10 80 	movl   $0x8010818a,(%esp)
80101bf9:	e8 3f e9 ff ff       	call   8010053d <panic>
}
80101bfe:	83 c4 24             	add    $0x24,%esp
80101c01:	5b                   	pop    %ebx
80101c02:	5d                   	pop    %ebp
80101c03:	c3                   	ret    

80101c04 <itrunc>:
// to it (no directory entries referring to it)
// and has no in-memory reference to it (is
// not an open file or current directory).
static void
itrunc(struct inode *ip)
{
80101c04:	55                   	push   %ebp
80101c05:	89 e5                	mov    %esp,%ebp
80101c07:	83 ec 28             	sub    $0x28,%esp
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101c0a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101c11:	eb 44                	jmp    80101c57 <itrunc+0x53>
    if(ip->addrs[i]){
80101c13:	8b 45 08             	mov    0x8(%ebp),%eax
80101c16:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c19:	83 c2 04             	add    $0x4,%edx
80101c1c:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101c20:	85 c0                	test   %eax,%eax
80101c22:	74 2f                	je     80101c53 <itrunc+0x4f>
      bfree(ip->dev, ip->addrs[i]);
80101c24:	8b 45 08             	mov    0x8(%ebp),%eax
80101c27:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c2a:	83 c2 04             	add    $0x4,%edx
80101c2d:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80101c31:	8b 45 08             	mov    0x8(%ebp),%eax
80101c34:	8b 00                	mov    (%eax),%eax
80101c36:	89 54 24 04          	mov    %edx,0x4(%esp)
80101c3a:	89 04 24             	mov    %eax,(%esp)
80101c3d:	e8 90 f8 ff ff       	call   801014d2 <bfree>
      ip->addrs[i] = 0;
80101c42:	8b 45 08             	mov    0x8(%ebp),%eax
80101c45:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c48:	83 c2 04             	add    $0x4,%edx
80101c4b:	c7 44 90 0c 00 00 00 	movl   $0x0,0xc(%eax,%edx,4)
80101c52:	00 
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101c53:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101c57:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
80101c5b:	7e b6                	jle    80101c13 <itrunc+0xf>
      bfree(ip->dev, ip->addrs[i]);
      ip->addrs[i] = 0;
    }
  }
  
  if(ip->addrs[NDIRECT]){
80101c5d:	8b 45 08             	mov    0x8(%ebp),%eax
80101c60:	8b 40 4c             	mov    0x4c(%eax),%eax
80101c63:	85 c0                	test   %eax,%eax
80101c65:	0f 84 8f 00 00 00    	je     80101cfa <itrunc+0xf6>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
80101c6b:	8b 45 08             	mov    0x8(%ebp),%eax
80101c6e:	8b 50 4c             	mov    0x4c(%eax),%edx
80101c71:	8b 45 08             	mov    0x8(%ebp),%eax
80101c74:	8b 00                	mov    (%eax),%eax
80101c76:	89 54 24 04          	mov    %edx,0x4(%esp)
80101c7a:	89 04 24             	mov    %eax,(%esp)
80101c7d:	e8 24 e5 ff ff       	call   801001a6 <bread>
80101c82:	89 45 ec             	mov    %eax,-0x14(%ebp)
    a = (uint*)bp->data;
80101c85:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101c88:	83 c0 18             	add    $0x18,%eax
80101c8b:	89 45 e8             	mov    %eax,-0x18(%ebp)
    for(j = 0; j < NINDIRECT; j++){
80101c8e:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80101c95:	eb 2f                	jmp    80101cc6 <itrunc+0xc2>
      if(a[j])
80101c97:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101c9a:	c1 e0 02             	shl    $0x2,%eax
80101c9d:	03 45 e8             	add    -0x18(%ebp),%eax
80101ca0:	8b 00                	mov    (%eax),%eax
80101ca2:	85 c0                	test   %eax,%eax
80101ca4:	74 1c                	je     80101cc2 <itrunc+0xbe>
        bfree(ip->dev, a[j]);
80101ca6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ca9:	c1 e0 02             	shl    $0x2,%eax
80101cac:	03 45 e8             	add    -0x18(%ebp),%eax
80101caf:	8b 10                	mov    (%eax),%edx
80101cb1:	8b 45 08             	mov    0x8(%ebp),%eax
80101cb4:	8b 00                	mov    (%eax),%eax
80101cb6:	89 54 24 04          	mov    %edx,0x4(%esp)
80101cba:	89 04 24             	mov    %eax,(%esp)
80101cbd:	e8 10 f8 ff ff       	call   801014d2 <bfree>
  }
  
  if(ip->addrs[NDIRECT]){
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    a = (uint*)bp->data;
    for(j = 0; j < NINDIRECT; j++){
80101cc2:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80101cc6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101cc9:	83 f8 7f             	cmp    $0x7f,%eax
80101ccc:	76 c9                	jbe    80101c97 <itrunc+0x93>
      if(a[j])
        bfree(ip->dev, a[j]);
    }
    brelse(bp);
80101cce:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101cd1:	89 04 24             	mov    %eax,(%esp)
80101cd4:	e8 3e e5 ff ff       	call   80100217 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
80101cd9:	8b 45 08             	mov    0x8(%ebp),%eax
80101cdc:	8b 50 4c             	mov    0x4c(%eax),%edx
80101cdf:	8b 45 08             	mov    0x8(%ebp),%eax
80101ce2:	8b 00                	mov    (%eax),%eax
80101ce4:	89 54 24 04          	mov    %edx,0x4(%esp)
80101ce8:	89 04 24             	mov    %eax,(%esp)
80101ceb:	e8 e2 f7 ff ff       	call   801014d2 <bfree>
    ip->addrs[NDIRECT] = 0;
80101cf0:	8b 45 08             	mov    0x8(%ebp),%eax
80101cf3:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
  }

  ip->size = 0;
80101cfa:	8b 45 08             	mov    0x8(%ebp),%eax
80101cfd:	c7 40 18 00 00 00 00 	movl   $0x0,0x18(%eax)
  iupdate(ip);
80101d04:	8b 45 08             	mov    0x8(%ebp),%eax
80101d07:	89 04 24             	mov    %eax,(%esp)
80101d0a:	e8 95 f9 ff ff       	call   801016a4 <iupdate>
}
80101d0f:	c9                   	leave  
80101d10:	c3                   	ret    

80101d11 <stati>:

// Copy stat information from inode.
void
stati(struct inode *ip, struct stat *st)
{
80101d11:	55                   	push   %ebp
80101d12:	89 e5                	mov    %esp,%ebp
  st->dev = ip->dev;
80101d14:	8b 45 08             	mov    0x8(%ebp),%eax
80101d17:	8b 00                	mov    (%eax),%eax
80101d19:	89 c2                	mov    %eax,%edx
80101d1b:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d1e:	89 50 04             	mov    %edx,0x4(%eax)
  st->ino = ip->inum;
80101d21:	8b 45 08             	mov    0x8(%ebp),%eax
80101d24:	8b 50 04             	mov    0x4(%eax),%edx
80101d27:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d2a:	89 50 08             	mov    %edx,0x8(%eax)
  st->type = ip->type;
80101d2d:	8b 45 08             	mov    0x8(%ebp),%eax
80101d30:	0f b7 50 10          	movzwl 0x10(%eax),%edx
80101d34:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d37:	66 89 10             	mov    %dx,(%eax)
  st->nlink = ip->nlink;
80101d3a:	8b 45 08             	mov    0x8(%ebp),%eax
80101d3d:	0f b7 50 16          	movzwl 0x16(%eax),%edx
80101d41:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d44:	66 89 50 0c          	mov    %dx,0xc(%eax)
  st->size = ip->size;
80101d48:	8b 45 08             	mov    0x8(%ebp),%eax
80101d4b:	8b 50 18             	mov    0x18(%eax),%edx
80101d4e:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d51:	89 50 10             	mov    %edx,0x10(%eax)
}
80101d54:	5d                   	pop    %ebp
80101d55:	c3                   	ret    

80101d56 <readi>:

//PAGEBREAK!
// Read data from inode.
int
readi(struct inode *ip, char *dst, uint off, uint n)
{
80101d56:	55                   	push   %ebp
80101d57:	89 e5                	mov    %esp,%ebp
80101d59:	53                   	push   %ebx
80101d5a:	83 ec 24             	sub    $0x24,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80101d5d:	8b 45 08             	mov    0x8(%ebp),%eax
80101d60:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101d64:	66 83 f8 03          	cmp    $0x3,%ax
80101d68:	75 60                	jne    80101dca <readi+0x74>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
80101d6a:	8b 45 08             	mov    0x8(%ebp),%eax
80101d6d:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101d71:	66 85 c0             	test   %ax,%ax
80101d74:	78 20                	js     80101d96 <readi+0x40>
80101d76:	8b 45 08             	mov    0x8(%ebp),%eax
80101d79:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101d7d:	66 83 f8 09          	cmp    $0x9,%ax
80101d81:	7f 13                	jg     80101d96 <readi+0x40>
80101d83:	8b 45 08             	mov    0x8(%ebp),%eax
80101d86:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101d8a:	98                   	cwtl   
80101d8b:	8b 04 c5 00 e8 10 80 	mov    -0x7fef1800(,%eax,8),%eax
80101d92:	85 c0                	test   %eax,%eax
80101d94:	75 0a                	jne    80101da0 <readi+0x4a>
      return -1;
80101d96:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101d9b:	e9 1b 01 00 00       	jmp    80101ebb <readi+0x165>
    return devsw[ip->major].read(ip, dst, n);
80101da0:	8b 45 08             	mov    0x8(%ebp),%eax
80101da3:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101da7:	98                   	cwtl   
80101da8:	8b 14 c5 00 e8 10 80 	mov    -0x7fef1800(,%eax,8),%edx
80101daf:	8b 45 14             	mov    0x14(%ebp),%eax
80101db2:	89 44 24 08          	mov    %eax,0x8(%esp)
80101db6:	8b 45 0c             	mov    0xc(%ebp),%eax
80101db9:	89 44 24 04          	mov    %eax,0x4(%esp)
80101dbd:	8b 45 08             	mov    0x8(%ebp),%eax
80101dc0:	89 04 24             	mov    %eax,(%esp)
80101dc3:	ff d2                	call   *%edx
80101dc5:	e9 f1 00 00 00       	jmp    80101ebb <readi+0x165>
  }

  if(off > ip->size || off + n < off)
80101dca:	8b 45 08             	mov    0x8(%ebp),%eax
80101dcd:	8b 40 18             	mov    0x18(%eax),%eax
80101dd0:	3b 45 10             	cmp    0x10(%ebp),%eax
80101dd3:	72 0d                	jb     80101de2 <readi+0x8c>
80101dd5:	8b 45 14             	mov    0x14(%ebp),%eax
80101dd8:	8b 55 10             	mov    0x10(%ebp),%edx
80101ddb:	01 d0                	add    %edx,%eax
80101ddd:	3b 45 10             	cmp    0x10(%ebp),%eax
80101de0:	73 0a                	jae    80101dec <readi+0x96>
    return -1;
80101de2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101de7:	e9 cf 00 00 00       	jmp    80101ebb <readi+0x165>
  if(off + n > ip->size)
80101dec:	8b 45 14             	mov    0x14(%ebp),%eax
80101def:	8b 55 10             	mov    0x10(%ebp),%edx
80101df2:	01 c2                	add    %eax,%edx
80101df4:	8b 45 08             	mov    0x8(%ebp),%eax
80101df7:	8b 40 18             	mov    0x18(%eax),%eax
80101dfa:	39 c2                	cmp    %eax,%edx
80101dfc:	76 0c                	jbe    80101e0a <readi+0xb4>
    n = ip->size - off;
80101dfe:	8b 45 08             	mov    0x8(%ebp),%eax
80101e01:	8b 40 18             	mov    0x18(%eax),%eax
80101e04:	2b 45 10             	sub    0x10(%ebp),%eax
80101e07:	89 45 14             	mov    %eax,0x14(%ebp)

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80101e0a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101e11:	e9 96 00 00 00       	jmp    80101eac <readi+0x156>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80101e16:	8b 45 10             	mov    0x10(%ebp),%eax
80101e19:	c1 e8 09             	shr    $0x9,%eax
80101e1c:	89 44 24 04          	mov    %eax,0x4(%esp)
80101e20:	8b 45 08             	mov    0x8(%ebp),%eax
80101e23:	89 04 24             	mov    %eax,(%esp)
80101e26:	e8 d7 fc ff ff       	call   80101b02 <bmap>
80101e2b:	8b 55 08             	mov    0x8(%ebp),%edx
80101e2e:	8b 12                	mov    (%edx),%edx
80101e30:	89 44 24 04          	mov    %eax,0x4(%esp)
80101e34:	89 14 24             	mov    %edx,(%esp)
80101e37:	e8 6a e3 ff ff       	call   801001a6 <bread>
80101e3c:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80101e3f:	8b 45 10             	mov    0x10(%ebp),%eax
80101e42:	89 c2                	mov    %eax,%edx
80101e44:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80101e4a:	b8 00 02 00 00       	mov    $0x200,%eax
80101e4f:	89 c1                	mov    %eax,%ecx
80101e51:	29 d1                	sub    %edx,%ecx
80101e53:	89 ca                	mov    %ecx,%edx
80101e55:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101e58:	8b 4d 14             	mov    0x14(%ebp),%ecx
80101e5b:	89 cb                	mov    %ecx,%ebx
80101e5d:	29 c3                	sub    %eax,%ebx
80101e5f:	89 d8                	mov    %ebx,%eax
80101e61:	39 c2                	cmp    %eax,%edx
80101e63:	0f 46 c2             	cmovbe %edx,%eax
80101e66:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dst, bp->data + off%BSIZE, m);
80101e69:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101e6c:	8d 50 18             	lea    0x18(%eax),%edx
80101e6f:	8b 45 10             	mov    0x10(%ebp),%eax
80101e72:	25 ff 01 00 00       	and    $0x1ff,%eax
80101e77:	01 c2                	add    %eax,%edx
80101e79:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101e7c:	89 44 24 08          	mov    %eax,0x8(%esp)
80101e80:	89 54 24 04          	mov    %edx,0x4(%esp)
80101e84:	8b 45 0c             	mov    0xc(%ebp),%eax
80101e87:	89 04 24             	mov    %eax,(%esp)
80101e8a:	e8 56 2f 00 00       	call   80104de5 <memmove>
    brelse(bp);
80101e8f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101e92:	89 04 24             	mov    %eax,(%esp)
80101e95:	e8 7d e3 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80101e9a:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101e9d:	01 45 f4             	add    %eax,-0xc(%ebp)
80101ea0:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101ea3:	01 45 10             	add    %eax,0x10(%ebp)
80101ea6:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101ea9:	01 45 0c             	add    %eax,0xc(%ebp)
80101eac:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101eaf:	3b 45 14             	cmp    0x14(%ebp),%eax
80101eb2:	0f 82 5e ff ff ff    	jb     80101e16 <readi+0xc0>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    memmove(dst, bp->data + off%BSIZE, m);
    brelse(bp);
  }
  return n;
80101eb8:	8b 45 14             	mov    0x14(%ebp),%eax
}
80101ebb:	83 c4 24             	add    $0x24,%esp
80101ebe:	5b                   	pop    %ebx
80101ebf:	5d                   	pop    %ebp
80101ec0:	c3                   	ret    

80101ec1 <writei>:

// PAGEBREAK!
// Write data to inode.
int
writei(struct inode *ip, char *src, uint off, uint n)
{
80101ec1:	55                   	push   %ebp
80101ec2:	89 e5                	mov    %esp,%ebp
80101ec4:	53                   	push   %ebx
80101ec5:	83 ec 24             	sub    $0x24,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80101ec8:	8b 45 08             	mov    0x8(%ebp),%eax
80101ecb:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101ecf:	66 83 f8 03          	cmp    $0x3,%ax
80101ed3:	75 60                	jne    80101f35 <writei+0x74>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
80101ed5:	8b 45 08             	mov    0x8(%ebp),%eax
80101ed8:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101edc:	66 85 c0             	test   %ax,%ax
80101edf:	78 20                	js     80101f01 <writei+0x40>
80101ee1:	8b 45 08             	mov    0x8(%ebp),%eax
80101ee4:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101ee8:	66 83 f8 09          	cmp    $0x9,%ax
80101eec:	7f 13                	jg     80101f01 <writei+0x40>
80101eee:	8b 45 08             	mov    0x8(%ebp),%eax
80101ef1:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101ef5:	98                   	cwtl   
80101ef6:	8b 04 c5 04 e8 10 80 	mov    -0x7fef17fc(,%eax,8),%eax
80101efd:	85 c0                	test   %eax,%eax
80101eff:	75 0a                	jne    80101f0b <writei+0x4a>
      return -1;
80101f01:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101f06:	e9 46 01 00 00       	jmp    80102051 <writei+0x190>
    return devsw[ip->major].write(ip, src, n);
80101f0b:	8b 45 08             	mov    0x8(%ebp),%eax
80101f0e:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101f12:	98                   	cwtl   
80101f13:	8b 14 c5 04 e8 10 80 	mov    -0x7fef17fc(,%eax,8),%edx
80101f1a:	8b 45 14             	mov    0x14(%ebp),%eax
80101f1d:	89 44 24 08          	mov    %eax,0x8(%esp)
80101f21:	8b 45 0c             	mov    0xc(%ebp),%eax
80101f24:	89 44 24 04          	mov    %eax,0x4(%esp)
80101f28:	8b 45 08             	mov    0x8(%ebp),%eax
80101f2b:	89 04 24             	mov    %eax,(%esp)
80101f2e:	ff d2                	call   *%edx
80101f30:	e9 1c 01 00 00       	jmp    80102051 <writei+0x190>
  }

  if(off > ip->size || off + n < off)
80101f35:	8b 45 08             	mov    0x8(%ebp),%eax
80101f38:	8b 40 18             	mov    0x18(%eax),%eax
80101f3b:	3b 45 10             	cmp    0x10(%ebp),%eax
80101f3e:	72 0d                	jb     80101f4d <writei+0x8c>
80101f40:	8b 45 14             	mov    0x14(%ebp),%eax
80101f43:	8b 55 10             	mov    0x10(%ebp),%edx
80101f46:	01 d0                	add    %edx,%eax
80101f48:	3b 45 10             	cmp    0x10(%ebp),%eax
80101f4b:	73 0a                	jae    80101f57 <writei+0x96>
    return -1;
80101f4d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101f52:	e9 fa 00 00 00       	jmp    80102051 <writei+0x190>
  if(off + n > MAXFILE*BSIZE)
80101f57:	8b 45 14             	mov    0x14(%ebp),%eax
80101f5a:	8b 55 10             	mov    0x10(%ebp),%edx
80101f5d:	01 d0                	add    %edx,%eax
80101f5f:	3d 00 18 01 00       	cmp    $0x11800,%eax
80101f64:	76 0a                	jbe    80101f70 <writei+0xaf>
    return -1;
80101f66:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101f6b:	e9 e1 00 00 00       	jmp    80102051 <writei+0x190>

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80101f70:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101f77:	e9 a1 00 00 00       	jmp    8010201d <writei+0x15c>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80101f7c:	8b 45 10             	mov    0x10(%ebp),%eax
80101f7f:	c1 e8 09             	shr    $0x9,%eax
80101f82:	89 44 24 04          	mov    %eax,0x4(%esp)
80101f86:	8b 45 08             	mov    0x8(%ebp),%eax
80101f89:	89 04 24             	mov    %eax,(%esp)
80101f8c:	e8 71 fb ff ff       	call   80101b02 <bmap>
80101f91:	8b 55 08             	mov    0x8(%ebp),%edx
80101f94:	8b 12                	mov    (%edx),%edx
80101f96:	89 44 24 04          	mov    %eax,0x4(%esp)
80101f9a:	89 14 24             	mov    %edx,(%esp)
80101f9d:	e8 04 e2 ff ff       	call   801001a6 <bread>
80101fa2:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80101fa5:	8b 45 10             	mov    0x10(%ebp),%eax
80101fa8:	89 c2                	mov    %eax,%edx
80101faa:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80101fb0:	b8 00 02 00 00       	mov    $0x200,%eax
80101fb5:	89 c1                	mov    %eax,%ecx
80101fb7:	29 d1                	sub    %edx,%ecx
80101fb9:	89 ca                	mov    %ecx,%edx
80101fbb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101fbe:	8b 4d 14             	mov    0x14(%ebp),%ecx
80101fc1:	89 cb                	mov    %ecx,%ebx
80101fc3:	29 c3                	sub    %eax,%ebx
80101fc5:	89 d8                	mov    %ebx,%eax
80101fc7:	39 c2                	cmp    %eax,%edx
80101fc9:	0f 46 c2             	cmovbe %edx,%eax
80101fcc:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(bp->data + off%BSIZE, src, m);
80101fcf:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101fd2:	8d 50 18             	lea    0x18(%eax),%edx
80101fd5:	8b 45 10             	mov    0x10(%ebp),%eax
80101fd8:	25 ff 01 00 00       	and    $0x1ff,%eax
80101fdd:	01 c2                	add    %eax,%edx
80101fdf:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101fe2:	89 44 24 08          	mov    %eax,0x8(%esp)
80101fe6:	8b 45 0c             	mov    0xc(%ebp),%eax
80101fe9:	89 44 24 04          	mov    %eax,0x4(%esp)
80101fed:	89 14 24             	mov    %edx,(%esp)
80101ff0:	e8 f0 2d 00 00       	call   80104de5 <memmove>
    log_write(bp);
80101ff5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ff8:	89 04 24             	mov    %eax,(%esp)
80101ffb:	e8 b6 12 00 00       	call   801032b6 <log_write>
    brelse(bp);
80102000:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102003:	89 04 24             	mov    %eax,(%esp)
80102006:	e8 0c e2 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > MAXFILE*BSIZE)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
8010200b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010200e:	01 45 f4             	add    %eax,-0xc(%ebp)
80102011:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102014:	01 45 10             	add    %eax,0x10(%ebp)
80102017:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010201a:	01 45 0c             	add    %eax,0xc(%ebp)
8010201d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102020:	3b 45 14             	cmp    0x14(%ebp),%eax
80102023:	0f 82 53 ff ff ff    	jb     80101f7c <writei+0xbb>
    memmove(bp->data + off%BSIZE, src, m);
    log_write(bp);
    brelse(bp);
  }

  if(n > 0 && off > ip->size){
80102029:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
8010202d:	74 1f                	je     8010204e <writei+0x18d>
8010202f:	8b 45 08             	mov    0x8(%ebp),%eax
80102032:	8b 40 18             	mov    0x18(%eax),%eax
80102035:	3b 45 10             	cmp    0x10(%ebp),%eax
80102038:	73 14                	jae    8010204e <writei+0x18d>
    ip->size = off;
8010203a:	8b 45 08             	mov    0x8(%ebp),%eax
8010203d:	8b 55 10             	mov    0x10(%ebp),%edx
80102040:	89 50 18             	mov    %edx,0x18(%eax)
    iupdate(ip);
80102043:	8b 45 08             	mov    0x8(%ebp),%eax
80102046:	89 04 24             	mov    %eax,(%esp)
80102049:	e8 56 f6 ff ff       	call   801016a4 <iupdate>
  }
  return n;
8010204e:	8b 45 14             	mov    0x14(%ebp),%eax
}
80102051:	83 c4 24             	add    $0x24,%esp
80102054:	5b                   	pop    %ebx
80102055:	5d                   	pop    %ebp
80102056:	c3                   	ret    

80102057 <namecmp>:
//PAGEBREAK!
// Directories

int
namecmp(const char *s, const char *t)
{
80102057:	55                   	push   %ebp
80102058:	89 e5                	mov    %esp,%ebp
8010205a:	83 ec 18             	sub    $0x18,%esp
  return strncmp(s, t, DIRSIZ);
8010205d:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80102064:	00 
80102065:	8b 45 0c             	mov    0xc(%ebp),%eax
80102068:	89 44 24 04          	mov    %eax,0x4(%esp)
8010206c:	8b 45 08             	mov    0x8(%ebp),%eax
8010206f:	89 04 24             	mov    %eax,(%esp)
80102072:	e8 12 2e 00 00       	call   80104e89 <strncmp>
}
80102077:	c9                   	leave  
80102078:	c3                   	ret    

80102079 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
80102079:	55                   	push   %ebp
8010207a:	89 e5                	mov    %esp,%ebp
8010207c:	83 ec 38             	sub    $0x38,%esp
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
8010207f:	8b 45 08             	mov    0x8(%ebp),%eax
80102082:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102086:	66 83 f8 01          	cmp    $0x1,%ax
8010208a:	74 0c                	je     80102098 <dirlookup+0x1f>
    panic("dirlookup not DIR");
8010208c:	c7 04 24 9d 81 10 80 	movl   $0x8010819d,(%esp)
80102093:	e8 a5 e4 ff ff       	call   8010053d <panic>

  for(off = 0; off < dp->size; off += sizeof(de)){
80102098:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010209f:	e9 87 00 00 00       	jmp    8010212b <dirlookup+0xb2>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801020a4:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801020ab:	00 
801020ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
801020af:	89 44 24 08          	mov    %eax,0x8(%esp)
801020b3:	8d 45 e0             	lea    -0x20(%ebp),%eax
801020b6:	89 44 24 04          	mov    %eax,0x4(%esp)
801020ba:	8b 45 08             	mov    0x8(%ebp),%eax
801020bd:	89 04 24             	mov    %eax,(%esp)
801020c0:	e8 91 fc ff ff       	call   80101d56 <readi>
801020c5:	83 f8 10             	cmp    $0x10,%eax
801020c8:	74 0c                	je     801020d6 <dirlookup+0x5d>
      panic("dirlink read");
801020ca:	c7 04 24 af 81 10 80 	movl   $0x801081af,(%esp)
801020d1:	e8 67 e4 ff ff       	call   8010053d <panic>
    if(de.inum == 0)
801020d6:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
801020da:	66 85 c0             	test   %ax,%ax
801020dd:	74 47                	je     80102126 <dirlookup+0xad>
      continue;
    if(namecmp(name, de.name) == 0){
801020df:	8d 45 e0             	lea    -0x20(%ebp),%eax
801020e2:	83 c0 02             	add    $0x2,%eax
801020e5:	89 44 24 04          	mov    %eax,0x4(%esp)
801020e9:	8b 45 0c             	mov    0xc(%ebp),%eax
801020ec:	89 04 24             	mov    %eax,(%esp)
801020ef:	e8 63 ff ff ff       	call   80102057 <namecmp>
801020f4:	85 c0                	test   %eax,%eax
801020f6:	75 2f                	jne    80102127 <dirlookup+0xae>
      // entry matches path element
      if(poff)
801020f8:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801020fc:	74 08                	je     80102106 <dirlookup+0x8d>
        *poff = off;
801020fe:	8b 45 10             	mov    0x10(%ebp),%eax
80102101:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102104:	89 10                	mov    %edx,(%eax)
      inum = de.inum;
80102106:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
8010210a:	0f b7 c0             	movzwl %ax,%eax
8010210d:	89 45 f0             	mov    %eax,-0x10(%ebp)
      return iget(dp->dev, inum);
80102110:	8b 45 08             	mov    0x8(%ebp),%eax
80102113:	8b 00                	mov    (%eax),%eax
80102115:	8b 55 f0             	mov    -0x10(%ebp),%edx
80102118:	89 54 24 04          	mov    %edx,0x4(%esp)
8010211c:	89 04 24             	mov    %eax,(%esp)
8010211f:	e8 38 f6 ff ff       	call   8010175c <iget>
80102124:	eb 19                	jmp    8010213f <dirlookup+0xc6>

  for(off = 0; off < dp->size; off += sizeof(de)){
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
    if(de.inum == 0)
      continue;
80102126:	90                   	nop
  struct dirent de;

  if(dp->type != T_DIR)
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
80102127:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
8010212b:	8b 45 08             	mov    0x8(%ebp),%eax
8010212e:	8b 40 18             	mov    0x18(%eax),%eax
80102131:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80102134:	0f 87 6a ff ff ff    	ja     801020a4 <dirlookup+0x2b>
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
8010213a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010213f:	c9                   	leave  
80102140:	c3                   	ret    

80102141 <dirlink>:

// Write a new directory entry (name, inum) into the directory dp.
int
dirlink(struct inode *dp, char *name, uint inum)
{
80102141:	55                   	push   %ebp
80102142:	89 e5                	mov    %esp,%ebp
80102144:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;
  struct inode *ip;

  // Check that name is not present.
  if((ip = dirlookup(dp, name, 0)) != 0){
80102147:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010214e:	00 
8010214f:	8b 45 0c             	mov    0xc(%ebp),%eax
80102152:	89 44 24 04          	mov    %eax,0x4(%esp)
80102156:	8b 45 08             	mov    0x8(%ebp),%eax
80102159:	89 04 24             	mov    %eax,(%esp)
8010215c:	e8 18 ff ff ff       	call   80102079 <dirlookup>
80102161:	89 45 f0             	mov    %eax,-0x10(%ebp)
80102164:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80102168:	74 15                	je     8010217f <dirlink+0x3e>
    iput(ip);
8010216a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010216d:	89 04 24             	mov    %eax,(%esp)
80102170:	e8 9e f8 ff ff       	call   80101a13 <iput>
    return -1;
80102175:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010217a:	e9 b8 00 00 00       	jmp    80102237 <dirlink+0xf6>
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
8010217f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102186:	eb 44                	jmp    801021cc <dirlink+0x8b>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102188:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010218b:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102192:	00 
80102193:	89 44 24 08          	mov    %eax,0x8(%esp)
80102197:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010219a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010219e:	8b 45 08             	mov    0x8(%ebp),%eax
801021a1:	89 04 24             	mov    %eax,(%esp)
801021a4:	e8 ad fb ff ff       	call   80101d56 <readi>
801021a9:	83 f8 10             	cmp    $0x10,%eax
801021ac:	74 0c                	je     801021ba <dirlink+0x79>
      panic("dirlink read");
801021ae:	c7 04 24 af 81 10 80 	movl   $0x801081af,(%esp)
801021b5:	e8 83 e3 ff ff       	call   8010053d <panic>
    if(de.inum == 0)
801021ba:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
801021be:	66 85 c0             	test   %ax,%ax
801021c1:	74 18                	je     801021db <dirlink+0x9a>
    iput(ip);
    return -1;
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
801021c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801021c6:	83 c0 10             	add    $0x10,%eax
801021c9:	89 45 f4             	mov    %eax,-0xc(%ebp)
801021cc:	8b 55 f4             	mov    -0xc(%ebp),%edx
801021cf:	8b 45 08             	mov    0x8(%ebp),%eax
801021d2:	8b 40 18             	mov    0x18(%eax),%eax
801021d5:	39 c2                	cmp    %eax,%edx
801021d7:	72 af                	jb     80102188 <dirlink+0x47>
801021d9:	eb 01                	jmp    801021dc <dirlink+0x9b>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
    if(de.inum == 0)
      break;
801021db:	90                   	nop
  }

  strncpy(de.name, name, DIRSIZ);
801021dc:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
801021e3:	00 
801021e4:	8b 45 0c             	mov    0xc(%ebp),%eax
801021e7:	89 44 24 04          	mov    %eax,0x4(%esp)
801021eb:	8d 45 e0             	lea    -0x20(%ebp),%eax
801021ee:	83 c0 02             	add    $0x2,%eax
801021f1:	89 04 24             	mov    %eax,(%esp)
801021f4:	e8 e8 2c 00 00       	call   80104ee1 <strncpy>
  de.inum = inum;
801021f9:	8b 45 10             	mov    0x10(%ebp),%eax
801021fc:	66 89 45 e0          	mov    %ax,-0x20(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102200:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102203:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
8010220a:	00 
8010220b:	89 44 24 08          	mov    %eax,0x8(%esp)
8010220f:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102212:	89 44 24 04          	mov    %eax,0x4(%esp)
80102216:	8b 45 08             	mov    0x8(%ebp),%eax
80102219:	89 04 24             	mov    %eax,(%esp)
8010221c:	e8 a0 fc ff ff       	call   80101ec1 <writei>
80102221:	83 f8 10             	cmp    $0x10,%eax
80102224:	74 0c                	je     80102232 <dirlink+0xf1>
    panic("dirlink");
80102226:	c7 04 24 bc 81 10 80 	movl   $0x801081bc,(%esp)
8010222d:	e8 0b e3 ff ff       	call   8010053d <panic>
  
  return 0;
80102232:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102237:	c9                   	leave  
80102238:	c3                   	ret    

80102239 <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
80102239:	55                   	push   %ebp
8010223a:	89 e5                	mov    %esp,%ebp
8010223c:	83 ec 28             	sub    $0x28,%esp
  char *s;
  int len;

  while(*path == '/')
8010223f:	eb 04                	jmp    80102245 <skipelem+0xc>
    path++;
80102241:	83 45 08 01          	addl   $0x1,0x8(%ebp)
skipelem(char *path, char *name)
{
  char *s;
  int len;

  while(*path == '/')
80102245:	8b 45 08             	mov    0x8(%ebp),%eax
80102248:	0f b6 00             	movzbl (%eax),%eax
8010224b:	3c 2f                	cmp    $0x2f,%al
8010224d:	74 f2                	je     80102241 <skipelem+0x8>
    path++;
  if(*path == 0)
8010224f:	8b 45 08             	mov    0x8(%ebp),%eax
80102252:	0f b6 00             	movzbl (%eax),%eax
80102255:	84 c0                	test   %al,%al
80102257:	75 0a                	jne    80102263 <skipelem+0x2a>
    return 0;
80102259:	b8 00 00 00 00       	mov    $0x0,%eax
8010225e:	e9 86 00 00 00       	jmp    801022e9 <skipelem+0xb0>
  s = path;
80102263:	8b 45 08             	mov    0x8(%ebp),%eax
80102266:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(*path != '/' && *path != 0)
80102269:	eb 04                	jmp    8010226f <skipelem+0x36>
    path++;
8010226b:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  while(*path == '/')
    path++;
  if(*path == 0)
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
8010226f:	8b 45 08             	mov    0x8(%ebp),%eax
80102272:	0f b6 00             	movzbl (%eax),%eax
80102275:	3c 2f                	cmp    $0x2f,%al
80102277:	74 0a                	je     80102283 <skipelem+0x4a>
80102279:	8b 45 08             	mov    0x8(%ebp),%eax
8010227c:	0f b6 00             	movzbl (%eax),%eax
8010227f:	84 c0                	test   %al,%al
80102281:	75 e8                	jne    8010226b <skipelem+0x32>
    path++;
  len = path - s;
80102283:	8b 55 08             	mov    0x8(%ebp),%edx
80102286:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102289:	89 d1                	mov    %edx,%ecx
8010228b:	29 c1                	sub    %eax,%ecx
8010228d:	89 c8                	mov    %ecx,%eax
8010228f:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(len >= DIRSIZ)
80102292:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
80102296:	7e 1c                	jle    801022b4 <skipelem+0x7b>
    memmove(name, s, DIRSIZ);
80102298:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
8010229f:	00 
801022a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801022a3:	89 44 24 04          	mov    %eax,0x4(%esp)
801022a7:	8b 45 0c             	mov    0xc(%ebp),%eax
801022aa:	89 04 24             	mov    %eax,(%esp)
801022ad:	e8 33 2b 00 00       	call   80104de5 <memmove>
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
801022b2:	eb 28                	jmp    801022dc <skipelem+0xa3>
    path++;
  len = path - s;
  if(len >= DIRSIZ)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
801022b4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801022b7:	89 44 24 08          	mov    %eax,0x8(%esp)
801022bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801022be:	89 44 24 04          	mov    %eax,0x4(%esp)
801022c2:	8b 45 0c             	mov    0xc(%ebp),%eax
801022c5:	89 04 24             	mov    %eax,(%esp)
801022c8:	e8 18 2b 00 00       	call   80104de5 <memmove>
    name[len] = 0;
801022cd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801022d0:	03 45 0c             	add    0xc(%ebp),%eax
801022d3:	c6 00 00             	movb   $0x0,(%eax)
  }
  while(*path == '/')
801022d6:	eb 04                	jmp    801022dc <skipelem+0xa3>
    path++;
801022d8:	83 45 08 01          	addl   $0x1,0x8(%ebp)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
801022dc:	8b 45 08             	mov    0x8(%ebp),%eax
801022df:	0f b6 00             	movzbl (%eax),%eax
801022e2:	3c 2f                	cmp    $0x2f,%al
801022e4:	74 f2                	je     801022d8 <skipelem+0x9f>
    path++;
  return path;
801022e6:	8b 45 08             	mov    0x8(%ebp),%eax
}
801022e9:	c9                   	leave  
801022ea:	c3                   	ret    

801022eb <namex>:
// Look up and return the inode for a path name.
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
static struct inode*
namex(char *path, int nameiparent, char *name)
{
801022eb:	55                   	push   %ebp
801022ec:	89 e5                	mov    %esp,%ebp
801022ee:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *next;

  if(*path == '/')
801022f1:	8b 45 08             	mov    0x8(%ebp),%eax
801022f4:	0f b6 00             	movzbl (%eax),%eax
801022f7:	3c 2f                	cmp    $0x2f,%al
801022f9:	75 1c                	jne    80102317 <namex+0x2c>
    ip = iget(ROOTDEV, ROOTINO);
801022fb:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102302:	00 
80102303:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010230a:	e8 4d f4 ff ff       	call   8010175c <iget>
8010230f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
80102312:	e9 af 00 00 00       	jmp    801023c6 <namex+0xdb>
  struct inode *ip, *next;

  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);
80102317:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010231d:	8b 40 68             	mov    0x68(%eax),%eax
80102320:	89 04 24             	mov    %eax,(%esp)
80102323:	e8 06 f5 ff ff       	call   8010182e <idup>
80102328:	89 45 f4             	mov    %eax,-0xc(%ebp)

  while((path = skipelem(path, name)) != 0){
8010232b:	e9 96 00 00 00       	jmp    801023c6 <namex+0xdb>
    ilock(ip);
80102330:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102333:	89 04 24             	mov    %eax,(%esp)
80102336:	e8 25 f5 ff ff       	call   80101860 <ilock>
    if(ip->type != T_DIR){
8010233b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010233e:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102342:	66 83 f8 01          	cmp    $0x1,%ax
80102346:	74 15                	je     8010235d <namex+0x72>
      iunlockput(ip);
80102348:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010234b:	89 04 24             	mov    %eax,(%esp)
8010234e:	e8 91 f7 ff ff       	call   80101ae4 <iunlockput>
      return 0;
80102353:	b8 00 00 00 00       	mov    $0x0,%eax
80102358:	e9 a3 00 00 00       	jmp    80102400 <namex+0x115>
    }
    if(nameiparent && *path == '\0'){
8010235d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102361:	74 1d                	je     80102380 <namex+0x95>
80102363:	8b 45 08             	mov    0x8(%ebp),%eax
80102366:	0f b6 00             	movzbl (%eax),%eax
80102369:	84 c0                	test   %al,%al
8010236b:	75 13                	jne    80102380 <namex+0x95>
      // Stop one level early.
      iunlock(ip);
8010236d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102370:	89 04 24             	mov    %eax,(%esp)
80102373:	e8 36 f6 ff ff       	call   801019ae <iunlock>
      return ip;
80102378:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010237b:	e9 80 00 00 00       	jmp    80102400 <namex+0x115>
    }
    if((next = dirlookup(ip, name, 0)) == 0){
80102380:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80102387:	00 
80102388:	8b 45 10             	mov    0x10(%ebp),%eax
8010238b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010238f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102392:	89 04 24             	mov    %eax,(%esp)
80102395:	e8 df fc ff ff       	call   80102079 <dirlookup>
8010239a:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010239d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801023a1:	75 12                	jne    801023b5 <namex+0xca>
      iunlockput(ip);
801023a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023a6:	89 04 24             	mov    %eax,(%esp)
801023a9:	e8 36 f7 ff ff       	call   80101ae4 <iunlockput>
      return 0;
801023ae:	b8 00 00 00 00       	mov    $0x0,%eax
801023b3:	eb 4b                	jmp    80102400 <namex+0x115>
    }
    iunlockput(ip);
801023b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023b8:	89 04 24             	mov    %eax,(%esp)
801023bb:	e8 24 f7 ff ff       	call   80101ae4 <iunlockput>
    ip = next;
801023c0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801023c3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
801023c6:	8b 45 10             	mov    0x10(%ebp),%eax
801023c9:	89 44 24 04          	mov    %eax,0x4(%esp)
801023cd:	8b 45 08             	mov    0x8(%ebp),%eax
801023d0:	89 04 24             	mov    %eax,(%esp)
801023d3:	e8 61 fe ff ff       	call   80102239 <skipelem>
801023d8:	89 45 08             	mov    %eax,0x8(%ebp)
801023db:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801023df:	0f 85 4b ff ff ff    	jne    80102330 <namex+0x45>
      return 0;
    }
    iunlockput(ip);
    ip = next;
  }
  if(nameiparent){
801023e5:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801023e9:	74 12                	je     801023fd <namex+0x112>
    iput(ip);
801023eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023ee:	89 04 24             	mov    %eax,(%esp)
801023f1:	e8 1d f6 ff ff       	call   80101a13 <iput>
    return 0;
801023f6:	b8 00 00 00 00       	mov    $0x0,%eax
801023fb:	eb 03                	jmp    80102400 <namex+0x115>
  }
  return ip;
801023fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102400:	c9                   	leave  
80102401:	c3                   	ret    

80102402 <namei>:

struct inode*
namei(char *path)
{
80102402:	55                   	push   %ebp
80102403:	89 e5                	mov    %esp,%ebp
80102405:	83 ec 28             	sub    $0x28,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
80102408:	8d 45 ea             	lea    -0x16(%ebp),%eax
8010240b:	89 44 24 08          	mov    %eax,0x8(%esp)
8010240f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102416:	00 
80102417:	8b 45 08             	mov    0x8(%ebp),%eax
8010241a:	89 04 24             	mov    %eax,(%esp)
8010241d:	e8 c9 fe ff ff       	call   801022eb <namex>
}
80102422:	c9                   	leave  
80102423:	c3                   	ret    

80102424 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
80102424:	55                   	push   %ebp
80102425:	89 e5                	mov    %esp,%ebp
80102427:	83 ec 18             	sub    $0x18,%esp
  return namex(path, 1, name);
8010242a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010242d:	89 44 24 08          	mov    %eax,0x8(%esp)
80102431:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102438:	00 
80102439:	8b 45 08             	mov    0x8(%ebp),%eax
8010243c:	89 04 24             	mov    %eax,(%esp)
8010243f:	e8 a7 fe ff ff       	call   801022eb <namex>
}
80102444:	c9                   	leave  
80102445:	c3                   	ret    
	...

80102448 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102448:	55                   	push   %ebp
80102449:	89 e5                	mov    %esp,%ebp
8010244b:	53                   	push   %ebx
8010244c:	83 ec 14             	sub    $0x14,%esp
8010244f:	8b 45 08             	mov    0x8(%ebp),%eax
80102452:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102456:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
8010245a:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
8010245e:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80102462:	ec                   	in     (%dx),%al
80102463:	89 c3                	mov    %eax,%ebx
80102465:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80102468:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
8010246c:	83 c4 14             	add    $0x14,%esp
8010246f:	5b                   	pop    %ebx
80102470:	5d                   	pop    %ebp
80102471:	c3                   	ret    

80102472 <insl>:

static inline void
insl(int port, void *addr, int cnt)
{
80102472:	55                   	push   %ebp
80102473:	89 e5                	mov    %esp,%ebp
80102475:	57                   	push   %edi
80102476:	53                   	push   %ebx
  asm volatile("cld; rep insl" :
80102477:	8b 55 08             	mov    0x8(%ebp),%edx
8010247a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
8010247d:	8b 45 10             	mov    0x10(%ebp),%eax
80102480:	89 cb                	mov    %ecx,%ebx
80102482:	89 df                	mov    %ebx,%edi
80102484:	89 c1                	mov    %eax,%ecx
80102486:	fc                   	cld    
80102487:	f3 6d                	rep insl (%dx),%es:(%edi)
80102489:	89 c8                	mov    %ecx,%eax
8010248b:	89 fb                	mov    %edi,%ebx
8010248d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
80102490:	89 45 10             	mov    %eax,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "memory", "cc");
}
80102493:	5b                   	pop    %ebx
80102494:	5f                   	pop    %edi
80102495:	5d                   	pop    %ebp
80102496:	c3                   	ret    

80102497 <outb>:

static inline void
outb(ushort port, uchar data)
{
80102497:	55                   	push   %ebp
80102498:	89 e5                	mov    %esp,%ebp
8010249a:	83 ec 08             	sub    $0x8,%esp
8010249d:	8b 55 08             	mov    0x8(%ebp),%edx
801024a0:	8b 45 0c             	mov    0xc(%ebp),%eax
801024a3:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801024a7:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801024aa:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801024ae:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801024b2:	ee                   	out    %al,(%dx)
}
801024b3:	c9                   	leave  
801024b4:	c3                   	ret    

801024b5 <outsl>:
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
}

static inline void
outsl(int port, const void *addr, int cnt)
{
801024b5:	55                   	push   %ebp
801024b6:	89 e5                	mov    %esp,%ebp
801024b8:	56                   	push   %esi
801024b9:	53                   	push   %ebx
  asm volatile("cld; rep outsl" :
801024ba:	8b 55 08             	mov    0x8(%ebp),%edx
801024bd:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801024c0:	8b 45 10             	mov    0x10(%ebp),%eax
801024c3:	89 cb                	mov    %ecx,%ebx
801024c5:	89 de                	mov    %ebx,%esi
801024c7:	89 c1                	mov    %eax,%ecx
801024c9:	fc                   	cld    
801024ca:	f3 6f                	rep outsl %ds:(%esi),(%dx)
801024cc:	89 c8                	mov    %ecx,%eax
801024ce:	89 f3                	mov    %esi,%ebx
801024d0:	89 5d 0c             	mov    %ebx,0xc(%ebp)
801024d3:	89 45 10             	mov    %eax,0x10(%ebp)
               "=S" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "cc");
}
801024d6:	5b                   	pop    %ebx
801024d7:	5e                   	pop    %esi
801024d8:	5d                   	pop    %ebp
801024d9:	c3                   	ret    

801024da <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
801024da:	55                   	push   %ebp
801024db:	89 e5                	mov    %esp,%ebp
801024dd:	83 ec 14             	sub    $0x14,%esp
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY) 
801024e0:	90                   	nop
801024e1:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801024e8:	e8 5b ff ff ff       	call   80102448 <inb>
801024ed:	0f b6 c0             	movzbl %al,%eax
801024f0:	89 45 fc             	mov    %eax,-0x4(%ebp)
801024f3:	8b 45 fc             	mov    -0x4(%ebp),%eax
801024f6:	25 c0 00 00 00       	and    $0xc0,%eax
801024fb:	83 f8 40             	cmp    $0x40,%eax
801024fe:	75 e1                	jne    801024e1 <idewait+0x7>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
80102500:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102504:	74 11                	je     80102517 <idewait+0x3d>
80102506:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102509:	83 e0 21             	and    $0x21,%eax
8010250c:	85 c0                	test   %eax,%eax
8010250e:	74 07                	je     80102517 <idewait+0x3d>
    return -1;
80102510:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102515:	eb 05                	jmp    8010251c <idewait+0x42>
  return 0;
80102517:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010251c:	c9                   	leave  
8010251d:	c3                   	ret    

8010251e <ideinit>:

void
ideinit(void)
{
8010251e:	55                   	push   %ebp
8010251f:	89 e5                	mov    %esp,%ebp
80102521:	83 ec 28             	sub    $0x28,%esp
  int i;

  initlock(&idelock, "ide");
80102524:	c7 44 24 04 c4 81 10 	movl   $0x801081c4,0x4(%esp)
8010252b:	80 
8010252c:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102533:	e8 6a 25 00 00       	call   80104aa2 <initlock>
  picenable(IRQ_IDE);
80102538:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
8010253f:	e8 65 15 00 00       	call   80103aa9 <picenable>
  ioapicenable(IRQ_IDE, ncpu - 1);
80102544:	a1 00 ff 10 80       	mov    0x8010ff00,%eax
80102549:	83 e8 01             	sub    $0x1,%eax
8010254c:	89 44 24 04          	mov    %eax,0x4(%esp)
80102550:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
80102557:	e8 12 04 00 00       	call   8010296e <ioapicenable>
  idewait(0);
8010255c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102563:	e8 72 ff ff ff       	call   801024da <idewait>
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
80102568:	c7 44 24 04 f0 00 00 	movl   $0xf0,0x4(%esp)
8010256f:	00 
80102570:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102577:	e8 1b ff ff ff       	call   80102497 <outb>
  for(i=0; i<1000; i++){
8010257c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102583:	eb 20                	jmp    801025a5 <ideinit+0x87>
    if(inb(0x1f7) != 0){
80102585:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
8010258c:	e8 b7 fe ff ff       	call   80102448 <inb>
80102591:	84 c0                	test   %al,%al
80102593:	74 0c                	je     801025a1 <ideinit+0x83>
      havedisk1 = 1;
80102595:	c7 05 38 b6 10 80 01 	movl   $0x1,0x8010b638
8010259c:	00 00 00 
      break;
8010259f:	eb 0d                	jmp    801025ae <ideinit+0x90>
  ioapicenable(IRQ_IDE, ncpu - 1);
  idewait(0);
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
  for(i=0; i<1000; i++){
801025a1:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801025a5:	81 7d f4 e7 03 00 00 	cmpl   $0x3e7,-0xc(%ebp)
801025ac:	7e d7                	jle    80102585 <ideinit+0x67>
      break;
    }
  }
  
  // Switch back to disk 0.
  outb(0x1f6, 0xe0 | (0<<4));
801025ae:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
801025b5:	00 
801025b6:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
801025bd:	e8 d5 fe ff ff       	call   80102497 <outb>
}
801025c2:	c9                   	leave  
801025c3:	c3                   	ret    

801025c4 <idestart>:

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
801025c4:	55                   	push   %ebp
801025c5:	89 e5                	mov    %esp,%ebp
801025c7:	83 ec 18             	sub    $0x18,%esp
  if(b == 0)
801025ca:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801025ce:	75 0c                	jne    801025dc <idestart+0x18>
    panic("idestart");
801025d0:	c7 04 24 c8 81 10 80 	movl   $0x801081c8,(%esp)
801025d7:	e8 61 df ff ff       	call   8010053d <panic>

  idewait(0);
801025dc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801025e3:	e8 f2 fe ff ff       	call   801024da <idewait>
  outb(0x3f6, 0);  // generate interrupt
801025e8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801025ef:	00 
801025f0:	c7 04 24 f6 03 00 00 	movl   $0x3f6,(%esp)
801025f7:	e8 9b fe ff ff       	call   80102497 <outb>
  outb(0x1f2, 1);  // number of sectors
801025fc:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102603:	00 
80102604:	c7 04 24 f2 01 00 00 	movl   $0x1f2,(%esp)
8010260b:	e8 87 fe ff ff       	call   80102497 <outb>
  outb(0x1f3, b->sector & 0xff);
80102610:	8b 45 08             	mov    0x8(%ebp),%eax
80102613:	8b 40 08             	mov    0x8(%eax),%eax
80102616:	0f b6 c0             	movzbl %al,%eax
80102619:	89 44 24 04          	mov    %eax,0x4(%esp)
8010261d:	c7 04 24 f3 01 00 00 	movl   $0x1f3,(%esp)
80102624:	e8 6e fe ff ff       	call   80102497 <outb>
  outb(0x1f4, (b->sector >> 8) & 0xff);
80102629:	8b 45 08             	mov    0x8(%ebp),%eax
8010262c:	8b 40 08             	mov    0x8(%eax),%eax
8010262f:	c1 e8 08             	shr    $0x8,%eax
80102632:	0f b6 c0             	movzbl %al,%eax
80102635:	89 44 24 04          	mov    %eax,0x4(%esp)
80102639:	c7 04 24 f4 01 00 00 	movl   $0x1f4,(%esp)
80102640:	e8 52 fe ff ff       	call   80102497 <outb>
  outb(0x1f5, (b->sector >> 16) & 0xff);
80102645:	8b 45 08             	mov    0x8(%ebp),%eax
80102648:	8b 40 08             	mov    0x8(%eax),%eax
8010264b:	c1 e8 10             	shr    $0x10,%eax
8010264e:	0f b6 c0             	movzbl %al,%eax
80102651:	89 44 24 04          	mov    %eax,0x4(%esp)
80102655:	c7 04 24 f5 01 00 00 	movl   $0x1f5,(%esp)
8010265c:	e8 36 fe ff ff       	call   80102497 <outb>
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((b->sector>>24)&0x0f));
80102661:	8b 45 08             	mov    0x8(%ebp),%eax
80102664:	8b 40 04             	mov    0x4(%eax),%eax
80102667:	83 e0 01             	and    $0x1,%eax
8010266a:	89 c2                	mov    %eax,%edx
8010266c:	c1 e2 04             	shl    $0x4,%edx
8010266f:	8b 45 08             	mov    0x8(%ebp),%eax
80102672:	8b 40 08             	mov    0x8(%eax),%eax
80102675:	c1 e8 18             	shr    $0x18,%eax
80102678:	83 e0 0f             	and    $0xf,%eax
8010267b:	09 d0                	or     %edx,%eax
8010267d:	83 c8 e0             	or     $0xffffffe0,%eax
80102680:	0f b6 c0             	movzbl %al,%eax
80102683:	89 44 24 04          	mov    %eax,0x4(%esp)
80102687:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
8010268e:	e8 04 fe ff ff       	call   80102497 <outb>
  if(b->flags & B_DIRTY){
80102693:	8b 45 08             	mov    0x8(%ebp),%eax
80102696:	8b 00                	mov    (%eax),%eax
80102698:	83 e0 04             	and    $0x4,%eax
8010269b:	85 c0                	test   %eax,%eax
8010269d:	74 34                	je     801026d3 <idestart+0x10f>
    outb(0x1f7, IDE_CMD_WRITE);
8010269f:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
801026a6:	00 
801026a7:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801026ae:	e8 e4 fd ff ff       	call   80102497 <outb>
    outsl(0x1f0, b->data, 512/4);
801026b3:	8b 45 08             	mov    0x8(%ebp),%eax
801026b6:	83 c0 18             	add    $0x18,%eax
801026b9:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
801026c0:	00 
801026c1:	89 44 24 04          	mov    %eax,0x4(%esp)
801026c5:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
801026cc:	e8 e4 fd ff ff       	call   801024b5 <outsl>
801026d1:	eb 14                	jmp    801026e7 <idestart+0x123>
  } else {
    outb(0x1f7, IDE_CMD_READ);
801026d3:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
801026da:	00 
801026db:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801026e2:	e8 b0 fd ff ff       	call   80102497 <outb>
  }
}
801026e7:	c9                   	leave  
801026e8:	c3                   	ret    

801026e9 <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
801026e9:	55                   	push   %ebp
801026ea:	89 e5                	mov    %esp,%ebp
801026ec:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
801026ef:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
801026f6:	e8 c8 23 00 00       	call   80104ac3 <acquire>
  if((b = idequeue) == 0){
801026fb:	a1 34 b6 10 80       	mov    0x8010b634,%eax
80102700:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102703:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102707:	75 11                	jne    8010271a <ideintr+0x31>
    release(&idelock);
80102709:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102710:	e8 10 24 00 00       	call   80104b25 <release>
    // cprintf("spurious IDE interrupt\n");
    return;
80102715:	e9 90 00 00 00       	jmp    801027aa <ideintr+0xc1>
  }
  idequeue = b->qnext;
8010271a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010271d:	8b 40 14             	mov    0x14(%eax),%eax
80102720:	a3 34 b6 10 80       	mov    %eax,0x8010b634

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80102725:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102728:	8b 00                	mov    (%eax),%eax
8010272a:	83 e0 04             	and    $0x4,%eax
8010272d:	85 c0                	test   %eax,%eax
8010272f:	75 2e                	jne    8010275f <ideintr+0x76>
80102731:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102738:	e8 9d fd ff ff       	call   801024da <idewait>
8010273d:	85 c0                	test   %eax,%eax
8010273f:	78 1e                	js     8010275f <ideintr+0x76>
    insl(0x1f0, b->data, 512/4);
80102741:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102744:	83 c0 18             	add    $0x18,%eax
80102747:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
8010274e:	00 
8010274f:	89 44 24 04          	mov    %eax,0x4(%esp)
80102753:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
8010275a:	e8 13 fd ff ff       	call   80102472 <insl>
  
  // Wake process waiting for this buf.
  b->flags |= B_VALID;
8010275f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102762:	8b 00                	mov    (%eax),%eax
80102764:	89 c2                	mov    %eax,%edx
80102766:	83 ca 02             	or     $0x2,%edx
80102769:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010276c:	89 10                	mov    %edx,(%eax)
  b->flags &= ~B_DIRTY;
8010276e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102771:	8b 00                	mov    (%eax),%eax
80102773:	89 c2                	mov    %eax,%edx
80102775:	83 e2 fb             	and    $0xfffffffb,%edx
80102778:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010277b:	89 10                	mov    %edx,(%eax)
  wakeup(b);
8010277d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102780:	89 04 24             	mov    %eax,(%esp)
80102783:	e8 38 21 00 00       	call   801048c0 <wakeup>
  
  // Start disk on next buf in queue.
  if(idequeue != 0)
80102788:	a1 34 b6 10 80       	mov    0x8010b634,%eax
8010278d:	85 c0                	test   %eax,%eax
8010278f:	74 0d                	je     8010279e <ideintr+0xb5>
    idestart(idequeue);
80102791:	a1 34 b6 10 80       	mov    0x8010b634,%eax
80102796:	89 04 24             	mov    %eax,(%esp)
80102799:	e8 26 fe ff ff       	call   801025c4 <idestart>

  release(&idelock);
8010279e:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
801027a5:	e8 7b 23 00 00       	call   80104b25 <release>
}
801027aa:	c9                   	leave  
801027ab:	c3                   	ret    

801027ac <iderw>:
// Sync buf with disk. 
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
801027ac:	55                   	push   %ebp
801027ad:	89 e5                	mov    %esp,%ebp
801027af:	83 ec 28             	sub    $0x28,%esp
  struct buf **pp;

  if(!(b->flags & B_BUSY))
801027b2:	8b 45 08             	mov    0x8(%ebp),%eax
801027b5:	8b 00                	mov    (%eax),%eax
801027b7:	83 e0 01             	and    $0x1,%eax
801027ba:	85 c0                	test   %eax,%eax
801027bc:	75 0c                	jne    801027ca <iderw+0x1e>
    panic("iderw: buf not busy");
801027be:	c7 04 24 d1 81 10 80 	movl   $0x801081d1,(%esp)
801027c5:	e8 73 dd ff ff       	call   8010053d <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
801027ca:	8b 45 08             	mov    0x8(%ebp),%eax
801027cd:	8b 00                	mov    (%eax),%eax
801027cf:	83 e0 06             	and    $0x6,%eax
801027d2:	83 f8 02             	cmp    $0x2,%eax
801027d5:	75 0c                	jne    801027e3 <iderw+0x37>
    panic("iderw: nothing to do");
801027d7:	c7 04 24 e5 81 10 80 	movl   $0x801081e5,(%esp)
801027de:	e8 5a dd ff ff       	call   8010053d <panic>
  if(b->dev != 0 && !havedisk1)
801027e3:	8b 45 08             	mov    0x8(%ebp),%eax
801027e6:	8b 40 04             	mov    0x4(%eax),%eax
801027e9:	85 c0                	test   %eax,%eax
801027eb:	74 15                	je     80102802 <iderw+0x56>
801027ed:	a1 38 b6 10 80       	mov    0x8010b638,%eax
801027f2:	85 c0                	test   %eax,%eax
801027f4:	75 0c                	jne    80102802 <iderw+0x56>
    panic("iderw: ide disk 1 not present");
801027f6:	c7 04 24 fa 81 10 80 	movl   $0x801081fa,(%esp)
801027fd:	e8 3b dd ff ff       	call   8010053d <panic>

  acquire(&idelock);  //DOC:acquire-lock
80102802:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102809:	e8 b5 22 00 00       	call   80104ac3 <acquire>

  // Append b to idequeue.
  b->qnext = 0;
8010280e:	8b 45 08             	mov    0x8(%ebp),%eax
80102811:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80102818:	c7 45 f4 34 b6 10 80 	movl   $0x8010b634,-0xc(%ebp)
8010281f:	eb 0b                	jmp    8010282c <iderw+0x80>
80102821:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102824:	8b 00                	mov    (%eax),%eax
80102826:	83 c0 14             	add    $0x14,%eax
80102829:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010282c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010282f:	8b 00                	mov    (%eax),%eax
80102831:	85 c0                	test   %eax,%eax
80102833:	75 ec                	jne    80102821 <iderw+0x75>
    ;
  *pp = b;
80102835:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102838:	8b 55 08             	mov    0x8(%ebp),%edx
8010283b:	89 10                	mov    %edx,(%eax)
  
  // Start disk if necessary.
  if(idequeue == b)
8010283d:	a1 34 b6 10 80       	mov    0x8010b634,%eax
80102842:	3b 45 08             	cmp    0x8(%ebp),%eax
80102845:	75 22                	jne    80102869 <iderw+0xbd>
    idestart(b);
80102847:	8b 45 08             	mov    0x8(%ebp),%eax
8010284a:	89 04 24             	mov    %eax,(%esp)
8010284d:	e8 72 fd ff ff       	call   801025c4 <idestart>
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102852:	eb 15                	jmp    80102869 <iderw+0xbd>
    sleep(b, &idelock);
80102854:	c7 44 24 04 00 b6 10 	movl   $0x8010b600,0x4(%esp)
8010285b:	80 
8010285c:	8b 45 08             	mov    0x8(%ebp),%eax
8010285f:	89 04 24             	mov    %eax,(%esp)
80102862:	e8 80 1f 00 00       	call   801047e7 <sleep>
80102867:	eb 01                	jmp    8010286a <iderw+0xbe>
  // Start disk if necessary.
  if(idequeue == b)
    idestart(b);
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102869:	90                   	nop
8010286a:	8b 45 08             	mov    0x8(%ebp),%eax
8010286d:	8b 00                	mov    (%eax),%eax
8010286f:	83 e0 06             	and    $0x6,%eax
80102872:	83 f8 02             	cmp    $0x2,%eax
80102875:	75 dd                	jne    80102854 <iderw+0xa8>
    sleep(b, &idelock);
  }

  release(&idelock);
80102877:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
8010287e:	e8 a2 22 00 00       	call   80104b25 <release>
}
80102883:	c9                   	leave  
80102884:	c3                   	ret    
80102885:	00 00                	add    %al,(%eax)
	...

80102888 <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
80102888:	55                   	push   %ebp
80102889:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
8010288b:	a1 34 f8 10 80       	mov    0x8010f834,%eax
80102890:	8b 55 08             	mov    0x8(%ebp),%edx
80102893:	89 10                	mov    %edx,(%eax)
  return ioapic->data;
80102895:	a1 34 f8 10 80       	mov    0x8010f834,%eax
8010289a:	8b 40 10             	mov    0x10(%eax),%eax
}
8010289d:	5d                   	pop    %ebp
8010289e:	c3                   	ret    

8010289f <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
8010289f:	55                   	push   %ebp
801028a0:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
801028a2:	a1 34 f8 10 80       	mov    0x8010f834,%eax
801028a7:	8b 55 08             	mov    0x8(%ebp),%edx
801028aa:	89 10                	mov    %edx,(%eax)
  ioapic->data = data;
801028ac:	a1 34 f8 10 80       	mov    0x8010f834,%eax
801028b1:	8b 55 0c             	mov    0xc(%ebp),%edx
801028b4:	89 50 10             	mov    %edx,0x10(%eax)
}
801028b7:	5d                   	pop    %ebp
801028b8:	c3                   	ret    

801028b9 <ioapicinit>:

void
ioapicinit(void)
{
801028b9:	55                   	push   %ebp
801028ba:	89 e5                	mov    %esp,%ebp
801028bc:	83 ec 28             	sub    $0x28,%esp
  int i, id, maxintr;

  if(!ismp)
801028bf:	a1 04 f9 10 80       	mov    0x8010f904,%eax
801028c4:	85 c0                	test   %eax,%eax
801028c6:	0f 84 9f 00 00 00    	je     8010296b <ioapicinit+0xb2>
    return;

  ioapic = (volatile struct ioapic*)IOAPIC;
801028cc:	c7 05 34 f8 10 80 00 	movl   $0xfec00000,0x8010f834
801028d3:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
801028d6:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801028dd:	e8 a6 ff ff ff       	call   80102888 <ioapicread>
801028e2:	c1 e8 10             	shr    $0x10,%eax
801028e5:	25 ff 00 00 00       	and    $0xff,%eax
801028ea:	89 45 f0             	mov    %eax,-0x10(%ebp)
  id = ioapicread(REG_ID) >> 24;
801028ed:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801028f4:	e8 8f ff ff ff       	call   80102888 <ioapicread>
801028f9:	c1 e8 18             	shr    $0x18,%eax
801028fc:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(id != ioapicid)
801028ff:	0f b6 05 00 f9 10 80 	movzbl 0x8010f900,%eax
80102906:	0f b6 c0             	movzbl %al,%eax
80102909:	3b 45 ec             	cmp    -0x14(%ebp),%eax
8010290c:	74 0c                	je     8010291a <ioapicinit+0x61>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
8010290e:	c7 04 24 18 82 10 80 	movl   $0x80108218,(%esp)
80102915:	e8 87 da ff ff       	call   801003a1 <cprintf>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
8010291a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102921:	eb 3e                	jmp    80102961 <ioapicinit+0xa8>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
80102923:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102926:	83 c0 20             	add    $0x20,%eax
80102929:	0d 00 00 01 00       	or     $0x10000,%eax
8010292e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102931:	83 c2 08             	add    $0x8,%edx
80102934:	01 d2                	add    %edx,%edx
80102936:	89 44 24 04          	mov    %eax,0x4(%esp)
8010293a:	89 14 24             	mov    %edx,(%esp)
8010293d:	e8 5d ff ff ff       	call   8010289f <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
80102942:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102945:	83 c0 08             	add    $0x8,%eax
80102948:	01 c0                	add    %eax,%eax
8010294a:	83 c0 01             	add    $0x1,%eax
8010294d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102954:	00 
80102955:	89 04 24             	mov    %eax,(%esp)
80102958:	e8 42 ff ff ff       	call   8010289f <ioapicwrite>
  if(id != ioapicid)
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
8010295d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102961:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102964:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80102967:	7e ba                	jle    80102923 <ioapicinit+0x6a>
80102969:	eb 01                	jmp    8010296c <ioapicinit+0xb3>
ioapicinit(void)
{
  int i, id, maxintr;

  if(!ismp)
    return;
8010296b:	90                   	nop
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
    ioapicwrite(REG_TABLE+2*i+1, 0);
  }
}
8010296c:	c9                   	leave  
8010296d:	c3                   	ret    

8010296e <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
8010296e:	55                   	push   %ebp
8010296f:	89 e5                	mov    %esp,%ebp
80102971:	83 ec 08             	sub    $0x8,%esp
  if(!ismp)
80102974:	a1 04 f9 10 80       	mov    0x8010f904,%eax
80102979:	85 c0                	test   %eax,%eax
8010297b:	74 39                	je     801029b6 <ioapicenable+0x48>
    return;

  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
8010297d:	8b 45 08             	mov    0x8(%ebp),%eax
80102980:	83 c0 20             	add    $0x20,%eax
80102983:	8b 55 08             	mov    0x8(%ebp),%edx
80102986:	83 c2 08             	add    $0x8,%edx
80102989:	01 d2                	add    %edx,%edx
8010298b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010298f:	89 14 24             	mov    %edx,(%esp)
80102992:	e8 08 ff ff ff       	call   8010289f <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
80102997:	8b 45 0c             	mov    0xc(%ebp),%eax
8010299a:	c1 e0 18             	shl    $0x18,%eax
8010299d:	8b 55 08             	mov    0x8(%ebp),%edx
801029a0:	83 c2 08             	add    $0x8,%edx
801029a3:	01 d2                	add    %edx,%edx
801029a5:	83 c2 01             	add    $0x1,%edx
801029a8:	89 44 24 04          	mov    %eax,0x4(%esp)
801029ac:	89 14 24             	mov    %edx,(%esp)
801029af:	e8 eb fe ff ff       	call   8010289f <ioapicwrite>
801029b4:	eb 01                	jmp    801029b7 <ioapicenable+0x49>

void
ioapicenable(int irq, int cpunum)
{
  if(!ismp)
    return;
801029b6:	90                   	nop
  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
}
801029b7:	c9                   	leave  
801029b8:	c3                   	ret    
801029b9:	00 00                	add    %al,(%eax)
	...

801029bc <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
801029bc:	55                   	push   %ebp
801029bd:	89 e5                	mov    %esp,%ebp
801029bf:	8b 45 08             	mov    0x8(%ebp),%eax
801029c2:	05 00 00 00 80       	add    $0x80000000,%eax
801029c7:	5d                   	pop    %ebp
801029c8:	c3                   	ret    

801029c9 <kinit1>:
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
801029c9:	55                   	push   %ebp
801029ca:	89 e5                	mov    %esp,%ebp
801029cc:	83 ec 18             	sub    $0x18,%esp
  initlock(&kmem.lock, "kmem");
801029cf:	c7 44 24 04 4a 82 10 	movl   $0x8010824a,0x4(%esp)
801029d6:	80 
801029d7:	c7 04 24 40 f8 10 80 	movl   $0x8010f840,(%esp)
801029de:	e8 bf 20 00 00       	call   80104aa2 <initlock>
  kmem.use_lock = 0;
801029e3:	c7 05 74 f8 10 80 00 	movl   $0x0,0x8010f874
801029ea:	00 00 00 
  freerange(vstart, vend);
801029ed:	8b 45 0c             	mov    0xc(%ebp),%eax
801029f0:	89 44 24 04          	mov    %eax,0x4(%esp)
801029f4:	8b 45 08             	mov    0x8(%ebp),%eax
801029f7:	89 04 24             	mov    %eax,(%esp)
801029fa:	e8 26 00 00 00       	call   80102a25 <freerange>
}
801029ff:	c9                   	leave  
80102a00:	c3                   	ret    

80102a01 <kinit2>:

void
kinit2(void *vstart, void *vend)
{
80102a01:	55                   	push   %ebp
80102a02:	89 e5                	mov    %esp,%ebp
80102a04:	83 ec 18             	sub    $0x18,%esp
  freerange(vstart, vend);
80102a07:	8b 45 0c             	mov    0xc(%ebp),%eax
80102a0a:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a0e:	8b 45 08             	mov    0x8(%ebp),%eax
80102a11:	89 04 24             	mov    %eax,(%esp)
80102a14:	e8 0c 00 00 00       	call   80102a25 <freerange>
  kmem.use_lock = 1;
80102a19:	c7 05 74 f8 10 80 01 	movl   $0x1,0x8010f874
80102a20:	00 00 00 
}
80102a23:	c9                   	leave  
80102a24:	c3                   	ret    

80102a25 <freerange>:

void
freerange(void *vstart, void *vend)
{
80102a25:	55                   	push   %ebp
80102a26:	89 e5                	mov    %esp,%ebp
80102a28:	83 ec 28             	sub    $0x28,%esp
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
80102a2b:	8b 45 08             	mov    0x8(%ebp),%eax
80102a2e:	05 ff 0f 00 00       	add    $0xfff,%eax
80102a33:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80102a38:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102a3b:	eb 12                	jmp    80102a4f <freerange+0x2a>
    kfree(p);
80102a3d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a40:	89 04 24             	mov    %eax,(%esp)
80102a43:	e8 16 00 00 00       	call   80102a5e <kfree>
void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102a48:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80102a4f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a52:	05 00 10 00 00       	add    $0x1000,%eax
80102a57:	3b 45 0c             	cmp    0xc(%ebp),%eax
80102a5a:	76 e1                	jbe    80102a3d <freerange+0x18>
    kfree(p);
}
80102a5c:	c9                   	leave  
80102a5d:	c3                   	ret    

80102a5e <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
80102a5e:	55                   	push   %ebp
80102a5f:	89 e5                	mov    %esp,%ebp
80102a61:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if((uint)v % PGSIZE || v < end || v2p(v) >= PHYSTOP)
80102a64:	8b 45 08             	mov    0x8(%ebp),%eax
80102a67:	25 ff 0f 00 00       	and    $0xfff,%eax
80102a6c:	85 c0                	test   %eax,%eax
80102a6e:	75 1b                	jne    80102a8b <kfree+0x2d>
80102a70:	81 7d 08 fc 26 11 80 	cmpl   $0x801126fc,0x8(%ebp)
80102a77:	72 12                	jb     80102a8b <kfree+0x2d>
80102a79:	8b 45 08             	mov    0x8(%ebp),%eax
80102a7c:	89 04 24             	mov    %eax,(%esp)
80102a7f:	e8 38 ff ff ff       	call   801029bc <v2p>
80102a84:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80102a89:	76 0c                	jbe    80102a97 <kfree+0x39>
    panic("kfree");
80102a8b:	c7 04 24 4f 82 10 80 	movl   $0x8010824f,(%esp)
80102a92:	e8 a6 da ff ff       	call   8010053d <panic>

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80102a97:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80102a9e:	00 
80102a9f:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102aa6:	00 
80102aa7:	8b 45 08             	mov    0x8(%ebp),%eax
80102aaa:	89 04 24             	mov    %eax,(%esp)
80102aad:	e8 60 22 00 00       	call   80104d12 <memset>

  if(kmem.use_lock)
80102ab2:	a1 74 f8 10 80       	mov    0x8010f874,%eax
80102ab7:	85 c0                	test   %eax,%eax
80102ab9:	74 0c                	je     80102ac7 <kfree+0x69>
    acquire(&kmem.lock);
80102abb:	c7 04 24 40 f8 10 80 	movl   $0x8010f840,(%esp)
80102ac2:	e8 fc 1f 00 00       	call   80104ac3 <acquire>
  r = (struct run*)v;
80102ac7:	8b 45 08             	mov    0x8(%ebp),%eax
80102aca:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
80102acd:	8b 15 78 f8 10 80    	mov    0x8010f878,%edx
80102ad3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102ad6:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
80102ad8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102adb:	a3 78 f8 10 80       	mov    %eax,0x8010f878
  if(kmem.use_lock)
80102ae0:	a1 74 f8 10 80       	mov    0x8010f874,%eax
80102ae5:	85 c0                	test   %eax,%eax
80102ae7:	74 0c                	je     80102af5 <kfree+0x97>
    release(&kmem.lock);
80102ae9:	c7 04 24 40 f8 10 80 	movl   $0x8010f840,(%esp)
80102af0:	e8 30 20 00 00       	call   80104b25 <release>
}
80102af5:	c9                   	leave  
80102af6:	c3                   	ret    

80102af7 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
80102af7:	55                   	push   %ebp
80102af8:	89 e5                	mov    %esp,%ebp
80102afa:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if(kmem.use_lock)
80102afd:	a1 74 f8 10 80       	mov    0x8010f874,%eax
80102b02:	85 c0                	test   %eax,%eax
80102b04:	74 0c                	je     80102b12 <kalloc+0x1b>
    acquire(&kmem.lock);
80102b06:	c7 04 24 40 f8 10 80 	movl   $0x8010f840,(%esp)
80102b0d:	e8 b1 1f 00 00       	call   80104ac3 <acquire>
  r = kmem.freelist;
80102b12:	a1 78 f8 10 80       	mov    0x8010f878,%eax
80102b17:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
80102b1a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102b1e:	74 0a                	je     80102b2a <kalloc+0x33>
    kmem.freelist = r->next;
80102b20:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b23:	8b 00                	mov    (%eax),%eax
80102b25:	a3 78 f8 10 80       	mov    %eax,0x8010f878
  if(kmem.use_lock)
80102b2a:	a1 74 f8 10 80       	mov    0x8010f874,%eax
80102b2f:	85 c0                	test   %eax,%eax
80102b31:	74 0c                	je     80102b3f <kalloc+0x48>
    release(&kmem.lock);
80102b33:	c7 04 24 40 f8 10 80 	movl   $0x8010f840,(%esp)
80102b3a:	e8 e6 1f 00 00       	call   80104b25 <release>
  return (char*)r;
80102b3f:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102b42:	c9                   	leave  
80102b43:	c3                   	ret    

80102b44 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102b44:	55                   	push   %ebp
80102b45:	89 e5                	mov    %esp,%ebp
80102b47:	53                   	push   %ebx
80102b48:	83 ec 14             	sub    $0x14,%esp
80102b4b:	8b 45 08             	mov    0x8(%ebp),%eax
80102b4e:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102b52:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80102b56:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80102b5a:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80102b5e:	ec                   	in     (%dx),%al
80102b5f:	89 c3                	mov    %eax,%ebx
80102b61:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80102b64:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80102b68:	83 c4 14             	add    $0x14,%esp
80102b6b:	5b                   	pop    %ebx
80102b6c:	5d                   	pop    %ebp
80102b6d:	c3                   	ret    

80102b6e <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
80102b6e:	55                   	push   %ebp
80102b6f:	89 e5                	mov    %esp,%ebp
80102b71:	83 ec 14             	sub    $0x14,%esp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
80102b74:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80102b7b:	e8 c4 ff ff ff       	call   80102b44 <inb>
80102b80:	0f b6 c0             	movzbl %al,%eax
80102b83:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((st & KBS_DIB) == 0)
80102b86:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b89:	83 e0 01             	and    $0x1,%eax
80102b8c:	85 c0                	test   %eax,%eax
80102b8e:	75 0a                	jne    80102b9a <kbdgetc+0x2c>
    return -1;
80102b90:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102b95:	e9 23 01 00 00       	jmp    80102cbd <kbdgetc+0x14f>
  data = inb(KBDATAP);
80102b9a:	c7 04 24 60 00 00 00 	movl   $0x60,(%esp)
80102ba1:	e8 9e ff ff ff       	call   80102b44 <inb>
80102ba6:	0f b6 c0             	movzbl %al,%eax
80102ba9:	89 45 fc             	mov    %eax,-0x4(%ebp)

  if(data == 0xE0){
80102bac:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%ebp)
80102bb3:	75 17                	jne    80102bcc <kbdgetc+0x5e>
    shift |= E0ESC;
80102bb5:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102bba:	83 c8 40             	or     $0x40,%eax
80102bbd:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
    return 0;
80102bc2:	b8 00 00 00 00       	mov    $0x0,%eax
80102bc7:	e9 f1 00 00 00       	jmp    80102cbd <kbdgetc+0x14f>
  } else if(data & 0x80){
80102bcc:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102bcf:	25 80 00 00 00       	and    $0x80,%eax
80102bd4:	85 c0                	test   %eax,%eax
80102bd6:	74 45                	je     80102c1d <kbdgetc+0xaf>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
80102bd8:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102bdd:	83 e0 40             	and    $0x40,%eax
80102be0:	85 c0                	test   %eax,%eax
80102be2:	75 08                	jne    80102bec <kbdgetc+0x7e>
80102be4:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102be7:	83 e0 7f             	and    $0x7f,%eax
80102bea:	eb 03                	jmp    80102bef <kbdgetc+0x81>
80102bec:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102bef:	89 45 fc             	mov    %eax,-0x4(%ebp)
    shift &= ~(shiftcode[data] | E0ESC);
80102bf2:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102bf5:	05 20 90 10 80       	add    $0x80109020,%eax
80102bfa:	0f b6 00             	movzbl (%eax),%eax
80102bfd:	83 c8 40             	or     $0x40,%eax
80102c00:	0f b6 c0             	movzbl %al,%eax
80102c03:	f7 d0                	not    %eax
80102c05:	89 c2                	mov    %eax,%edx
80102c07:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102c0c:	21 d0                	and    %edx,%eax
80102c0e:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
    return 0;
80102c13:	b8 00 00 00 00       	mov    $0x0,%eax
80102c18:	e9 a0 00 00 00       	jmp    80102cbd <kbdgetc+0x14f>
  } else if(shift & E0ESC){
80102c1d:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102c22:	83 e0 40             	and    $0x40,%eax
80102c25:	85 c0                	test   %eax,%eax
80102c27:	74 14                	je     80102c3d <kbdgetc+0xcf>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
80102c29:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
80102c30:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102c35:	83 e0 bf             	and    $0xffffffbf,%eax
80102c38:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
  }

  shift |= shiftcode[data];
80102c3d:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102c40:	05 20 90 10 80       	add    $0x80109020,%eax
80102c45:	0f b6 00             	movzbl (%eax),%eax
80102c48:	0f b6 d0             	movzbl %al,%edx
80102c4b:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102c50:	09 d0                	or     %edx,%eax
80102c52:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
  shift ^= togglecode[data];
80102c57:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102c5a:	05 20 91 10 80       	add    $0x80109120,%eax
80102c5f:	0f b6 00             	movzbl (%eax),%eax
80102c62:	0f b6 d0             	movzbl %al,%edx
80102c65:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102c6a:	31 d0                	xor    %edx,%eax
80102c6c:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
  c = charcode[shift & (CTL | SHIFT)][data];
80102c71:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102c76:	83 e0 03             	and    $0x3,%eax
80102c79:	8b 04 85 20 95 10 80 	mov    -0x7fef6ae0(,%eax,4),%eax
80102c80:	03 45 fc             	add    -0x4(%ebp),%eax
80102c83:	0f b6 00             	movzbl (%eax),%eax
80102c86:	0f b6 c0             	movzbl %al,%eax
80102c89:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
80102c8c:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102c91:	83 e0 08             	and    $0x8,%eax
80102c94:	85 c0                	test   %eax,%eax
80102c96:	74 22                	je     80102cba <kbdgetc+0x14c>
    if('a' <= c && c <= 'z')
80102c98:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
80102c9c:	76 0c                	jbe    80102caa <kbdgetc+0x13c>
80102c9e:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
80102ca2:	77 06                	ja     80102caa <kbdgetc+0x13c>
      c += 'A' - 'a';
80102ca4:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
80102ca8:	eb 10                	jmp    80102cba <kbdgetc+0x14c>
    else if('A' <= c && c <= 'Z')
80102caa:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
80102cae:	76 0a                	jbe    80102cba <kbdgetc+0x14c>
80102cb0:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
80102cb4:	77 04                	ja     80102cba <kbdgetc+0x14c>
      c += 'a' - 'A';
80102cb6:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
  }
  return c;
80102cba:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80102cbd:	c9                   	leave  
80102cbe:	c3                   	ret    

80102cbf <kbdintr>:

void
kbdintr(void)
{
80102cbf:	55                   	push   %ebp
80102cc0:	89 e5                	mov    %esp,%ebp
80102cc2:	83 ec 18             	sub    $0x18,%esp
  consoleintr(kbdgetc);
80102cc5:	c7 04 24 6e 2b 10 80 	movl   $0x80102b6e,(%esp)
80102ccc:	e8 dc da ff ff       	call   801007ad <consoleintr>
}
80102cd1:	c9                   	leave  
80102cd2:	c3                   	ret    
	...

80102cd4 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80102cd4:	55                   	push   %ebp
80102cd5:	89 e5                	mov    %esp,%ebp
80102cd7:	83 ec 08             	sub    $0x8,%esp
80102cda:	8b 55 08             	mov    0x8(%ebp),%edx
80102cdd:	8b 45 0c             	mov    0xc(%ebp),%eax
80102ce0:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80102ce4:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102ce7:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80102ceb:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80102cef:	ee                   	out    %al,(%dx)
}
80102cf0:	c9                   	leave  
80102cf1:	c3                   	ret    

80102cf2 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80102cf2:	55                   	push   %ebp
80102cf3:	89 e5                	mov    %esp,%ebp
80102cf5:	53                   	push   %ebx
80102cf6:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80102cf9:	9c                   	pushf  
80102cfa:	5b                   	pop    %ebx
80102cfb:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80102cfe:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80102d01:	83 c4 10             	add    $0x10,%esp
80102d04:	5b                   	pop    %ebx
80102d05:	5d                   	pop    %ebp
80102d06:	c3                   	ret    

80102d07 <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
80102d07:	55                   	push   %ebp
80102d08:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
80102d0a:	a1 7c f8 10 80       	mov    0x8010f87c,%eax
80102d0f:	8b 55 08             	mov    0x8(%ebp),%edx
80102d12:	c1 e2 02             	shl    $0x2,%edx
80102d15:	01 c2                	add    %eax,%edx
80102d17:	8b 45 0c             	mov    0xc(%ebp),%eax
80102d1a:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
80102d1c:	a1 7c f8 10 80       	mov    0x8010f87c,%eax
80102d21:	83 c0 20             	add    $0x20,%eax
80102d24:	8b 00                	mov    (%eax),%eax
}
80102d26:	5d                   	pop    %ebp
80102d27:	c3                   	ret    

80102d28 <lapicinit>:
//PAGEBREAK!

void
lapicinit(void)
{
80102d28:	55                   	push   %ebp
80102d29:	89 e5                	mov    %esp,%ebp
80102d2b:	83 ec 08             	sub    $0x8,%esp
  if(!lapic) 
80102d2e:	a1 7c f8 10 80       	mov    0x8010f87c,%eax
80102d33:	85 c0                	test   %eax,%eax
80102d35:	0f 84 47 01 00 00    	je     80102e82 <lapicinit+0x15a>
    return;

  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
80102d3b:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
80102d42:	00 
80102d43:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
80102d4a:	e8 b8 ff ff ff       	call   80102d07 <lapicw>

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.  
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
80102d4f:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
80102d56:	00 
80102d57:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
80102d5e:	e8 a4 ff ff ff       	call   80102d07 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
80102d63:	c7 44 24 04 20 00 02 	movl   $0x20020,0x4(%esp)
80102d6a:	00 
80102d6b:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80102d72:	e8 90 ff ff ff       	call   80102d07 <lapicw>
  lapicw(TICR, 10000000); 
80102d77:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
80102d7e:	00 
80102d7f:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
80102d86:	e8 7c ff ff ff       	call   80102d07 <lapicw>

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
80102d8b:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102d92:	00 
80102d93:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
80102d9a:	e8 68 ff ff ff       	call   80102d07 <lapicw>
  lapicw(LINT1, MASKED);
80102d9f:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102da6:	00 
80102da7:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
80102dae:	e8 54 ff ff ff       	call   80102d07 <lapicw>

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
80102db3:	a1 7c f8 10 80       	mov    0x8010f87c,%eax
80102db8:	83 c0 30             	add    $0x30,%eax
80102dbb:	8b 00                	mov    (%eax),%eax
80102dbd:	c1 e8 10             	shr    $0x10,%eax
80102dc0:	25 ff 00 00 00       	and    $0xff,%eax
80102dc5:	83 f8 03             	cmp    $0x3,%eax
80102dc8:	76 14                	jbe    80102dde <lapicinit+0xb6>
    lapicw(PCINT, MASKED);
80102dca:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102dd1:	00 
80102dd2:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
80102dd9:	e8 29 ff ff ff       	call   80102d07 <lapicw>

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
80102dde:	c7 44 24 04 33 00 00 	movl   $0x33,0x4(%esp)
80102de5:	00 
80102de6:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
80102ded:	e8 15 ff ff ff       	call   80102d07 <lapicw>

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
80102df2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102df9:	00 
80102dfa:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80102e01:	e8 01 ff ff ff       	call   80102d07 <lapicw>
  lapicw(ESR, 0);
80102e06:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102e0d:	00 
80102e0e:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80102e15:	e8 ed fe ff ff       	call   80102d07 <lapicw>

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
80102e1a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102e21:	00 
80102e22:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80102e29:	e8 d9 fe ff ff       	call   80102d07 <lapicw>

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
80102e2e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102e35:	00 
80102e36:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80102e3d:	e8 c5 fe ff ff       	call   80102d07 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
80102e42:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
80102e49:	00 
80102e4a:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80102e51:	e8 b1 fe ff ff       	call   80102d07 <lapicw>
  while(lapic[ICRLO] & DELIVS)
80102e56:	90                   	nop
80102e57:	a1 7c f8 10 80       	mov    0x8010f87c,%eax
80102e5c:	05 00 03 00 00       	add    $0x300,%eax
80102e61:	8b 00                	mov    (%eax),%eax
80102e63:	25 00 10 00 00       	and    $0x1000,%eax
80102e68:	85 c0                	test   %eax,%eax
80102e6a:	75 eb                	jne    80102e57 <lapicinit+0x12f>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
80102e6c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102e73:	00 
80102e74:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80102e7b:	e8 87 fe ff ff       	call   80102d07 <lapicw>
80102e80:	eb 01                	jmp    80102e83 <lapicinit+0x15b>

void
lapicinit(void)
{
  if(!lapic) 
    return;
80102e82:	90                   	nop
  while(lapic[ICRLO] & DELIVS)
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
}
80102e83:	c9                   	leave  
80102e84:	c3                   	ret    

80102e85 <cpunum>:

int
cpunum(void)
{
80102e85:	55                   	push   %ebp
80102e86:	89 e5                	mov    %esp,%ebp
80102e88:	83 ec 18             	sub    $0x18,%esp
  // Cannot call cpu when interrupts are enabled:
  // result not guaranteed to last long enough to be used!
  // Would prefer to panic but even printing is chancy here:
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
80102e8b:	e8 62 fe ff ff       	call   80102cf2 <readeflags>
80102e90:	25 00 02 00 00       	and    $0x200,%eax
80102e95:	85 c0                	test   %eax,%eax
80102e97:	74 29                	je     80102ec2 <cpunum+0x3d>
    static int n;
    if(n++ == 0)
80102e99:	a1 40 b6 10 80       	mov    0x8010b640,%eax
80102e9e:	85 c0                	test   %eax,%eax
80102ea0:	0f 94 c2             	sete   %dl
80102ea3:	83 c0 01             	add    $0x1,%eax
80102ea6:	a3 40 b6 10 80       	mov    %eax,0x8010b640
80102eab:	84 d2                	test   %dl,%dl
80102ead:	74 13                	je     80102ec2 <cpunum+0x3d>
      cprintf("cpu called from %x with interrupts enabled\n",
80102eaf:	8b 45 04             	mov    0x4(%ebp),%eax
80102eb2:	89 44 24 04          	mov    %eax,0x4(%esp)
80102eb6:	c7 04 24 58 82 10 80 	movl   $0x80108258,(%esp)
80102ebd:	e8 df d4 ff ff       	call   801003a1 <cprintf>
        __builtin_return_address(0));
  }

  if(lapic)
80102ec2:	a1 7c f8 10 80       	mov    0x8010f87c,%eax
80102ec7:	85 c0                	test   %eax,%eax
80102ec9:	74 0f                	je     80102eda <cpunum+0x55>
    return lapic[ID]>>24;
80102ecb:	a1 7c f8 10 80       	mov    0x8010f87c,%eax
80102ed0:	83 c0 20             	add    $0x20,%eax
80102ed3:	8b 00                	mov    (%eax),%eax
80102ed5:	c1 e8 18             	shr    $0x18,%eax
80102ed8:	eb 05                	jmp    80102edf <cpunum+0x5a>
  return 0;
80102eda:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102edf:	c9                   	leave  
80102ee0:	c3                   	ret    

80102ee1 <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
80102ee1:	55                   	push   %ebp
80102ee2:	89 e5                	mov    %esp,%ebp
80102ee4:	83 ec 08             	sub    $0x8,%esp
  if(lapic)
80102ee7:	a1 7c f8 10 80       	mov    0x8010f87c,%eax
80102eec:	85 c0                	test   %eax,%eax
80102eee:	74 14                	je     80102f04 <lapiceoi+0x23>
    lapicw(EOI, 0);
80102ef0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102ef7:	00 
80102ef8:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80102eff:	e8 03 fe ff ff       	call   80102d07 <lapicw>
}
80102f04:	c9                   	leave  
80102f05:	c3                   	ret    

80102f06 <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
80102f06:	55                   	push   %ebp
80102f07:	89 e5                	mov    %esp,%ebp
}
80102f09:	5d                   	pop    %ebp
80102f0a:	c3                   	ret    

80102f0b <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
80102f0b:	55                   	push   %ebp
80102f0c:	89 e5                	mov    %esp,%ebp
80102f0e:	83 ec 1c             	sub    $0x1c,%esp
80102f11:	8b 45 08             	mov    0x8(%ebp),%eax
80102f14:	88 45 ec             	mov    %al,-0x14(%ebp)
  ushort *wrv;
  
  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
80102f17:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80102f1e:	00 
80102f1f:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
80102f26:	e8 a9 fd ff ff       	call   80102cd4 <outb>
  outb(IO_RTC+1, 0x0A);
80102f2b:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80102f32:	00 
80102f33:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
80102f3a:	e8 95 fd ff ff       	call   80102cd4 <outb>
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
80102f3f:	c7 45 f8 67 04 00 80 	movl   $0x80000467,-0x8(%ebp)
  wrv[0] = 0;
80102f46:	8b 45 f8             	mov    -0x8(%ebp),%eax
80102f49:	66 c7 00 00 00       	movw   $0x0,(%eax)
  wrv[1] = addr >> 4;
80102f4e:	8b 45 f8             	mov    -0x8(%ebp),%eax
80102f51:	8d 50 02             	lea    0x2(%eax),%edx
80102f54:	8b 45 0c             	mov    0xc(%ebp),%eax
80102f57:	c1 e8 04             	shr    $0x4,%eax
80102f5a:	66 89 02             	mov    %ax,(%edx)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
80102f5d:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80102f61:	c1 e0 18             	shl    $0x18,%eax
80102f64:	89 44 24 04          	mov    %eax,0x4(%esp)
80102f68:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80102f6f:	e8 93 fd ff ff       	call   80102d07 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
80102f74:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
80102f7b:	00 
80102f7c:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80102f83:	e8 7f fd ff ff       	call   80102d07 <lapicw>
  microdelay(200);
80102f88:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80102f8f:	e8 72 ff ff ff       	call   80102f06 <microdelay>
  lapicw(ICRLO, INIT | LEVEL);
80102f94:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
80102f9b:	00 
80102f9c:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80102fa3:	e8 5f fd ff ff       	call   80102d07 <lapicw>
  microdelay(100);    // should be 10ms, but too slow in Bochs!
80102fa8:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80102faf:	e8 52 ff ff ff       	call   80102f06 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80102fb4:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80102fbb:	eb 40                	jmp    80102ffd <lapicstartap+0xf2>
    lapicw(ICRHI, apicid<<24);
80102fbd:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80102fc1:	c1 e0 18             	shl    $0x18,%eax
80102fc4:	89 44 24 04          	mov    %eax,0x4(%esp)
80102fc8:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80102fcf:	e8 33 fd ff ff       	call   80102d07 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
80102fd4:	8b 45 0c             	mov    0xc(%ebp),%eax
80102fd7:	c1 e8 0c             	shr    $0xc,%eax
80102fda:	80 cc 06             	or     $0x6,%ah
80102fdd:	89 44 24 04          	mov    %eax,0x4(%esp)
80102fe1:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80102fe8:	e8 1a fd ff ff       	call   80102d07 <lapicw>
    microdelay(200);
80102fed:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80102ff4:	e8 0d ff ff ff       	call   80102f06 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80102ff9:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80102ffd:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
80103001:	7e ba                	jle    80102fbd <lapicstartap+0xb2>
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
80103003:	c9                   	leave  
80103004:	c3                   	ret    
80103005:	00 00                	add    %al,(%eax)
	...

80103008 <initlog>:

static void recover_from_log(void);

void
initlog(void)
{
80103008:	55                   	push   %ebp
80103009:	89 e5                	mov    %esp,%ebp
8010300b:	83 ec 28             	sub    $0x28,%esp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
8010300e:	c7 44 24 04 84 82 10 	movl   $0x80108284,0x4(%esp)
80103015:	80 
80103016:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
8010301d:	e8 80 1a 00 00       	call   80104aa2 <initlock>
  readsb(ROOTDEV, &sb);
80103022:	8d 45 e8             	lea    -0x18(%ebp),%eax
80103025:	89 44 24 04          	mov    %eax,0x4(%esp)
80103029:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103030:	e8 af e2 ff ff       	call   801012e4 <readsb>
  log.start = sb.size - sb.nlog;
80103035:	8b 55 e8             	mov    -0x18(%ebp),%edx
80103038:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010303b:	89 d1                	mov    %edx,%ecx
8010303d:	29 c1                	sub    %eax,%ecx
8010303f:	89 c8                	mov    %ecx,%eax
80103041:	a3 b4 f8 10 80       	mov    %eax,0x8010f8b4
  log.size = sb.nlog;
80103046:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103049:	a3 b8 f8 10 80       	mov    %eax,0x8010f8b8
  log.dev = ROOTDEV;
8010304e:	c7 05 c0 f8 10 80 01 	movl   $0x1,0x8010f8c0
80103055:	00 00 00 
  recover_from_log();
80103058:	e8 97 01 00 00       	call   801031f4 <recover_from_log>
}
8010305d:	c9                   	leave  
8010305e:	c3                   	ret    

8010305f <install_trans>:

// Copy committed blocks from log to their home location
static void 
install_trans(void)
{
8010305f:	55                   	push   %ebp
80103060:	89 e5                	mov    %esp,%ebp
80103062:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103065:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010306c:	e9 89 00 00 00       	jmp    801030fa <install_trans+0x9b>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
80103071:	a1 b4 f8 10 80       	mov    0x8010f8b4,%eax
80103076:	03 45 f4             	add    -0xc(%ebp),%eax
80103079:	83 c0 01             	add    $0x1,%eax
8010307c:	89 c2                	mov    %eax,%edx
8010307e:	a1 c0 f8 10 80       	mov    0x8010f8c0,%eax
80103083:	89 54 24 04          	mov    %edx,0x4(%esp)
80103087:	89 04 24             	mov    %eax,(%esp)
8010308a:	e8 17 d1 ff ff       	call   801001a6 <bread>
8010308f:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.sector[tail]); // read dst
80103092:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103095:	83 c0 10             	add    $0x10,%eax
80103098:	8b 04 85 88 f8 10 80 	mov    -0x7fef0778(,%eax,4),%eax
8010309f:	89 c2                	mov    %eax,%edx
801030a1:	a1 c0 f8 10 80       	mov    0x8010f8c0,%eax
801030a6:	89 54 24 04          	mov    %edx,0x4(%esp)
801030aa:	89 04 24             	mov    %eax,(%esp)
801030ad:	e8 f4 d0 ff ff       	call   801001a6 <bread>
801030b2:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
801030b5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801030b8:	8d 50 18             	lea    0x18(%eax),%edx
801030bb:	8b 45 ec             	mov    -0x14(%ebp),%eax
801030be:	83 c0 18             	add    $0x18,%eax
801030c1:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
801030c8:	00 
801030c9:	89 54 24 04          	mov    %edx,0x4(%esp)
801030cd:	89 04 24             	mov    %eax,(%esp)
801030d0:	e8 10 1d 00 00       	call   80104de5 <memmove>
    bwrite(dbuf);  // write dst to disk
801030d5:	8b 45 ec             	mov    -0x14(%ebp),%eax
801030d8:	89 04 24             	mov    %eax,(%esp)
801030db:	e8 fd d0 ff ff       	call   801001dd <bwrite>
    brelse(lbuf); 
801030e0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801030e3:	89 04 24             	mov    %eax,(%esp)
801030e6:	e8 2c d1 ff ff       	call   80100217 <brelse>
    brelse(dbuf);
801030eb:	8b 45 ec             	mov    -0x14(%ebp),%eax
801030ee:	89 04 24             	mov    %eax,(%esp)
801030f1:	e8 21 d1 ff ff       	call   80100217 <brelse>
static void 
install_trans(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
801030f6:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801030fa:	a1 c4 f8 10 80       	mov    0x8010f8c4,%eax
801030ff:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103102:	0f 8f 69 ff ff ff    	jg     80103071 <install_trans+0x12>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    bwrite(dbuf);  // write dst to disk
    brelse(lbuf); 
    brelse(dbuf);
  }
}
80103108:	c9                   	leave  
80103109:	c3                   	ret    

8010310a <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
8010310a:	55                   	push   %ebp
8010310b:	89 e5                	mov    %esp,%ebp
8010310d:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
80103110:	a1 b4 f8 10 80       	mov    0x8010f8b4,%eax
80103115:	89 c2                	mov    %eax,%edx
80103117:	a1 c0 f8 10 80       	mov    0x8010f8c0,%eax
8010311c:	89 54 24 04          	mov    %edx,0x4(%esp)
80103120:	89 04 24             	mov    %eax,(%esp)
80103123:	e8 7e d0 ff ff       	call   801001a6 <bread>
80103128:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *lh = (struct logheader *) (buf->data);
8010312b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010312e:	83 c0 18             	add    $0x18,%eax
80103131:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  log.lh.n = lh->n;
80103134:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103137:	8b 00                	mov    (%eax),%eax
80103139:	a3 c4 f8 10 80       	mov    %eax,0x8010f8c4
  for (i = 0; i < log.lh.n; i++) {
8010313e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103145:	eb 1b                	jmp    80103162 <read_head+0x58>
    log.lh.sector[i] = lh->sector[i];
80103147:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010314a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010314d:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
80103151:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103154:	83 c2 10             	add    $0x10,%edx
80103157:	89 04 95 88 f8 10 80 	mov    %eax,-0x7fef0778(,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
8010315e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103162:	a1 c4 f8 10 80       	mov    0x8010f8c4,%eax
80103167:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010316a:	7f db                	jg     80103147 <read_head+0x3d>
    log.lh.sector[i] = lh->sector[i];
  }
  brelse(buf);
8010316c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010316f:	89 04 24             	mov    %eax,(%esp)
80103172:	e8 a0 d0 ff ff       	call   80100217 <brelse>
}
80103177:	c9                   	leave  
80103178:	c3                   	ret    

80103179 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
80103179:	55                   	push   %ebp
8010317a:	89 e5                	mov    %esp,%ebp
8010317c:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
8010317f:	a1 b4 f8 10 80       	mov    0x8010f8b4,%eax
80103184:	89 c2                	mov    %eax,%edx
80103186:	a1 c0 f8 10 80       	mov    0x8010f8c0,%eax
8010318b:	89 54 24 04          	mov    %edx,0x4(%esp)
8010318f:	89 04 24             	mov    %eax,(%esp)
80103192:	e8 0f d0 ff ff       	call   801001a6 <bread>
80103197:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *hb = (struct logheader *) (buf->data);
8010319a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010319d:	83 c0 18             	add    $0x18,%eax
801031a0:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  hb->n = log.lh.n;
801031a3:	8b 15 c4 f8 10 80    	mov    0x8010f8c4,%edx
801031a9:	8b 45 ec             	mov    -0x14(%ebp),%eax
801031ac:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
801031ae:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801031b5:	eb 1b                	jmp    801031d2 <write_head+0x59>
    hb->sector[i] = log.lh.sector[i];
801031b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801031ba:	83 c0 10             	add    $0x10,%eax
801031bd:	8b 0c 85 88 f8 10 80 	mov    -0x7fef0778(,%eax,4),%ecx
801031c4:	8b 45 ec             	mov    -0x14(%ebp),%eax
801031c7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801031ca:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
  for (i = 0; i < log.lh.n; i++) {
801031ce:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801031d2:	a1 c4 f8 10 80       	mov    0x8010f8c4,%eax
801031d7:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801031da:	7f db                	jg     801031b7 <write_head+0x3e>
    hb->sector[i] = log.lh.sector[i];
  }
  bwrite(buf);
801031dc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801031df:	89 04 24             	mov    %eax,(%esp)
801031e2:	e8 f6 cf ff ff       	call   801001dd <bwrite>
  brelse(buf);
801031e7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801031ea:	89 04 24             	mov    %eax,(%esp)
801031ed:	e8 25 d0 ff ff       	call   80100217 <brelse>
}
801031f2:	c9                   	leave  
801031f3:	c3                   	ret    

801031f4 <recover_from_log>:

static void
recover_from_log(void)
{
801031f4:	55                   	push   %ebp
801031f5:	89 e5                	mov    %esp,%ebp
801031f7:	83 ec 08             	sub    $0x8,%esp
  read_head();      
801031fa:	e8 0b ff ff ff       	call   8010310a <read_head>
  install_trans(); // if committed, copy from log to disk
801031ff:	e8 5b fe ff ff       	call   8010305f <install_trans>
  log.lh.n = 0;
80103204:	c7 05 c4 f8 10 80 00 	movl   $0x0,0x8010f8c4
8010320b:	00 00 00 
  write_head(); // clear the log
8010320e:	e8 66 ff ff ff       	call   80103179 <write_head>
}
80103213:	c9                   	leave  
80103214:	c3                   	ret    

80103215 <begin_trans>:

void
begin_trans(void)
{
80103215:	55                   	push   %ebp
80103216:	89 e5                	mov    %esp,%ebp
80103218:	83 ec 18             	sub    $0x18,%esp
  acquire(&log.lock);
8010321b:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
80103222:	e8 9c 18 00 00       	call   80104ac3 <acquire>
  while (log.busy) {
80103227:	eb 14                	jmp    8010323d <begin_trans+0x28>
    sleep(&log, &log.lock);
80103229:	c7 44 24 04 80 f8 10 	movl   $0x8010f880,0x4(%esp)
80103230:	80 
80103231:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
80103238:	e8 aa 15 00 00       	call   801047e7 <sleep>

void
begin_trans(void)
{
  acquire(&log.lock);
  while (log.busy) {
8010323d:	a1 bc f8 10 80       	mov    0x8010f8bc,%eax
80103242:	85 c0                	test   %eax,%eax
80103244:	75 e3                	jne    80103229 <begin_trans+0x14>
    sleep(&log, &log.lock);
  }
  log.busy = 1;
80103246:	c7 05 bc f8 10 80 01 	movl   $0x1,0x8010f8bc
8010324d:	00 00 00 
  release(&log.lock);
80103250:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
80103257:	e8 c9 18 00 00       	call   80104b25 <release>
}
8010325c:	c9                   	leave  
8010325d:	c3                   	ret    

8010325e <commit_trans>:

void
commit_trans(void)
{
8010325e:	55                   	push   %ebp
8010325f:	89 e5                	mov    %esp,%ebp
80103261:	83 ec 18             	sub    $0x18,%esp
  if (log.lh.n > 0) {
80103264:	a1 c4 f8 10 80       	mov    0x8010f8c4,%eax
80103269:	85 c0                	test   %eax,%eax
8010326b:	7e 19                	jle    80103286 <commit_trans+0x28>
    write_head();    // Write header to disk -- the real commit
8010326d:	e8 07 ff ff ff       	call   80103179 <write_head>
    install_trans(); // Now install writes to home locations
80103272:	e8 e8 fd ff ff       	call   8010305f <install_trans>
    log.lh.n = 0; 
80103277:	c7 05 c4 f8 10 80 00 	movl   $0x0,0x8010f8c4
8010327e:	00 00 00 
    write_head();    // Erase the transaction from the log
80103281:	e8 f3 fe ff ff       	call   80103179 <write_head>
  }
  
  acquire(&log.lock);
80103286:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
8010328d:	e8 31 18 00 00       	call   80104ac3 <acquire>
  log.busy = 0;
80103292:	c7 05 bc f8 10 80 00 	movl   $0x0,0x8010f8bc
80103299:	00 00 00 
  wakeup(&log);
8010329c:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
801032a3:	e8 18 16 00 00       	call   801048c0 <wakeup>
  release(&log.lock);
801032a8:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
801032af:	e8 71 18 00 00       	call   80104b25 <release>
}
801032b4:	c9                   	leave  
801032b5:	c3                   	ret    

801032b6 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
801032b6:	55                   	push   %ebp
801032b7:	89 e5                	mov    %esp,%ebp
801032b9:	83 ec 28             	sub    $0x28,%esp
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
801032bc:	a1 c4 f8 10 80       	mov    0x8010f8c4,%eax
801032c1:	83 f8 09             	cmp    $0x9,%eax
801032c4:	7f 12                	jg     801032d8 <log_write+0x22>
801032c6:	a1 c4 f8 10 80       	mov    0x8010f8c4,%eax
801032cb:	8b 15 b8 f8 10 80    	mov    0x8010f8b8,%edx
801032d1:	83 ea 01             	sub    $0x1,%edx
801032d4:	39 d0                	cmp    %edx,%eax
801032d6:	7c 0c                	jl     801032e4 <log_write+0x2e>
    panic("too big a transaction");
801032d8:	c7 04 24 88 82 10 80 	movl   $0x80108288,(%esp)
801032df:	e8 59 d2 ff ff       	call   8010053d <panic>
  if (!log.busy)
801032e4:	a1 bc f8 10 80       	mov    0x8010f8bc,%eax
801032e9:	85 c0                	test   %eax,%eax
801032eb:	75 0c                	jne    801032f9 <log_write+0x43>
    panic("write outside of trans");
801032ed:	c7 04 24 9e 82 10 80 	movl   $0x8010829e,(%esp)
801032f4:	e8 44 d2 ff ff       	call   8010053d <panic>

  for (i = 0; i < log.lh.n; i++) {
801032f9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103300:	eb 1d                	jmp    8010331f <log_write+0x69>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
80103302:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103305:	83 c0 10             	add    $0x10,%eax
80103308:	8b 04 85 88 f8 10 80 	mov    -0x7fef0778(,%eax,4),%eax
8010330f:	89 c2                	mov    %eax,%edx
80103311:	8b 45 08             	mov    0x8(%ebp),%eax
80103314:	8b 40 08             	mov    0x8(%eax),%eax
80103317:	39 c2                	cmp    %eax,%edx
80103319:	74 10                	je     8010332b <log_write+0x75>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    panic("too big a transaction");
  if (!log.busy)
    panic("write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
8010331b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010331f:	a1 c4 f8 10 80       	mov    0x8010f8c4,%eax
80103324:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103327:	7f d9                	jg     80103302 <log_write+0x4c>
80103329:	eb 01                	jmp    8010332c <log_write+0x76>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
      break;
8010332b:	90                   	nop
  }
  log.lh.sector[i] = b->sector;
8010332c:	8b 45 08             	mov    0x8(%ebp),%eax
8010332f:	8b 40 08             	mov    0x8(%eax),%eax
80103332:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103335:	83 c2 10             	add    $0x10,%edx
80103338:	89 04 95 88 f8 10 80 	mov    %eax,-0x7fef0778(,%edx,4)
  struct buf *lbuf = bread(b->dev, log.start+i+1);
8010333f:	a1 b4 f8 10 80       	mov    0x8010f8b4,%eax
80103344:	03 45 f4             	add    -0xc(%ebp),%eax
80103347:	83 c0 01             	add    $0x1,%eax
8010334a:	89 c2                	mov    %eax,%edx
8010334c:	8b 45 08             	mov    0x8(%ebp),%eax
8010334f:	8b 40 04             	mov    0x4(%eax),%eax
80103352:	89 54 24 04          	mov    %edx,0x4(%esp)
80103356:	89 04 24             	mov    %eax,(%esp)
80103359:	e8 48 ce ff ff       	call   801001a6 <bread>
8010335e:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(lbuf->data, b->data, BSIZE);
80103361:	8b 45 08             	mov    0x8(%ebp),%eax
80103364:	8d 50 18             	lea    0x18(%eax),%edx
80103367:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010336a:	83 c0 18             	add    $0x18,%eax
8010336d:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80103374:	00 
80103375:	89 54 24 04          	mov    %edx,0x4(%esp)
80103379:	89 04 24             	mov    %eax,(%esp)
8010337c:	e8 64 1a 00 00       	call   80104de5 <memmove>
  bwrite(lbuf);
80103381:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103384:	89 04 24             	mov    %eax,(%esp)
80103387:	e8 51 ce ff ff       	call   801001dd <bwrite>
  brelse(lbuf);
8010338c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010338f:	89 04 24             	mov    %eax,(%esp)
80103392:	e8 80 ce ff ff       	call   80100217 <brelse>
  if (i == log.lh.n)
80103397:	a1 c4 f8 10 80       	mov    0x8010f8c4,%eax
8010339c:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010339f:	75 0d                	jne    801033ae <log_write+0xf8>
    log.lh.n++;
801033a1:	a1 c4 f8 10 80       	mov    0x8010f8c4,%eax
801033a6:	83 c0 01             	add    $0x1,%eax
801033a9:	a3 c4 f8 10 80       	mov    %eax,0x8010f8c4
  b->flags |= B_DIRTY; // XXX prevent eviction
801033ae:	8b 45 08             	mov    0x8(%ebp),%eax
801033b1:	8b 00                	mov    (%eax),%eax
801033b3:	89 c2                	mov    %eax,%edx
801033b5:	83 ca 04             	or     $0x4,%edx
801033b8:	8b 45 08             	mov    0x8(%ebp),%eax
801033bb:	89 10                	mov    %edx,(%eax)
}
801033bd:	c9                   	leave  
801033be:	c3                   	ret    
	...

801033c0 <v2p>:
801033c0:	55                   	push   %ebp
801033c1:	89 e5                	mov    %esp,%ebp
801033c3:	8b 45 08             	mov    0x8(%ebp),%eax
801033c6:	05 00 00 00 80       	add    $0x80000000,%eax
801033cb:	5d                   	pop    %ebp
801033cc:	c3                   	ret    

801033cd <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
801033cd:	55                   	push   %ebp
801033ce:	89 e5                	mov    %esp,%ebp
801033d0:	8b 45 08             	mov    0x8(%ebp),%eax
801033d3:	05 00 00 00 80       	add    $0x80000000,%eax
801033d8:	5d                   	pop    %ebp
801033d9:	c3                   	ret    

801033da <xchg>:
  asm volatile("sti");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
801033da:	55                   	push   %ebp
801033db:	89 e5                	mov    %esp,%ebp
801033dd:	53                   	push   %ebx
801033de:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
801033e1:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
801033e4:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
801033e7:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
801033ea:	89 c3                	mov    %eax,%ebx
801033ec:	89 d8                	mov    %ebx,%eax
801033ee:	f0 87 02             	lock xchg %eax,(%edx)
801033f1:	89 c3                	mov    %eax,%ebx
801033f3:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
801033f6:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
801033f9:	83 c4 10             	add    $0x10,%esp
801033fc:	5b                   	pop    %ebx
801033fd:	5d                   	pop    %ebp
801033fe:	c3                   	ret    

801033ff <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
801033ff:	55                   	push   %ebp
80103400:	89 e5                	mov    %esp,%ebp
80103402:	83 e4 f0             	and    $0xfffffff0,%esp
80103405:	83 ec 10             	sub    $0x10,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80103408:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
8010340f:	80 
80103410:	c7 04 24 fc 26 11 80 	movl   $0x801126fc,(%esp)
80103417:	e8 ad f5 ff ff       	call   801029c9 <kinit1>
  kvmalloc();      // kernel page table
8010341c:	e8 ad 44 00 00       	call   801078ce <kvmalloc>
  mpinit();        // collect info about this machine
80103421:	e8 53 04 00 00       	call   80103879 <mpinit>
  lapicinit();
80103426:	e8 fd f8 ff ff       	call   80102d28 <lapicinit>
  seginit();       // set up segments
8010342b:	e8 41 3e 00 00       	call   80107271 <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
80103430:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103436:	0f b6 00             	movzbl (%eax),%eax
80103439:	0f b6 c0             	movzbl %al,%eax
8010343c:	89 44 24 04          	mov    %eax,0x4(%esp)
80103440:	c7 04 24 b5 82 10 80 	movl   $0x801082b5,(%esp)
80103447:	e8 55 cf ff ff       	call   801003a1 <cprintf>
  picinit();       // interrupt controller
8010344c:	e8 8d 06 00 00       	call   80103ade <picinit>
  ioapicinit();    // another interrupt controller
80103451:	e8 63 f4 ff ff       	call   801028b9 <ioapicinit>
  consoleinit();   // I/O devices & their interrupts
80103456:	e8 32 d6 ff ff       	call   80100a8d <consoleinit>
  uartinit();      // serial port
8010345b:	e8 5c 31 00 00       	call   801065bc <uartinit>
  pinit();         // process table
80103460:	e8 8e 0b 00 00       	call   80103ff3 <pinit>
  tvinit();        // trap vectors
80103465:	e8 f5 2c 00 00       	call   8010615f <tvinit>
  binit();         // buffer cache
8010346a:	e8 c5 cb ff ff       	call   80100034 <binit>
  fileinit();      // file table
8010346f:	e8 84 da ff ff       	call   80100ef8 <fileinit>
  iinit();         // inode cache
80103474:	e8 32 e1 ff ff       	call   801015ab <iinit>
  ideinit();       // disk
80103479:	e8 a0 f0 ff ff       	call   8010251e <ideinit>
  if(!ismp)
8010347e:	a1 04 f9 10 80       	mov    0x8010f904,%eax
80103483:	85 c0                	test   %eax,%eax
80103485:	75 05                	jne    8010348c <main+0x8d>
    timerinit();   // uniprocessor timer
80103487:	e8 16 2c 00 00       	call   801060a2 <timerinit>
  startothers();   // start other processors
8010348c:	e8 7f 00 00 00       	call   80103510 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80103491:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
80103498:	8e 
80103499:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
801034a0:	e8 5c f5 ff ff       	call   80102a01 <kinit2>
  userinit();      // first user process
801034a5:	e8 45 0c 00 00       	call   801040ef <userinit>
  // Finish setting up this processor in mpmain.
  mpmain();
801034aa:	e8 1a 00 00 00       	call   801034c9 <mpmain>

801034af <mpenter>:
}

// Other CPUs jump here from entryother.S.
static void
mpenter(void)
{
801034af:	55                   	push   %ebp
801034b0:	89 e5                	mov    %esp,%ebp
801034b2:	83 ec 08             	sub    $0x8,%esp
  switchkvm(); 
801034b5:	e8 2b 44 00 00       	call   801078e5 <switchkvm>
  seginit();
801034ba:	e8 b2 3d 00 00       	call   80107271 <seginit>
  lapicinit();
801034bf:	e8 64 f8 ff ff       	call   80102d28 <lapicinit>
  mpmain();
801034c4:	e8 00 00 00 00       	call   801034c9 <mpmain>

801034c9 <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
801034c9:	55                   	push   %ebp
801034ca:	89 e5                	mov    %esp,%ebp
801034cc:	83 ec 18             	sub    $0x18,%esp
  cprintf("cpu%d: starting\n", cpu->id);
801034cf:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801034d5:	0f b6 00             	movzbl (%eax),%eax
801034d8:	0f b6 c0             	movzbl %al,%eax
801034db:	89 44 24 04          	mov    %eax,0x4(%esp)
801034df:	c7 04 24 cc 82 10 80 	movl   $0x801082cc,(%esp)
801034e6:	e8 b6 ce ff ff       	call   801003a1 <cprintf>
  idtinit();       // load idt register
801034eb:	e8 e3 2d 00 00       	call   801062d3 <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
801034f0:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801034f6:	05 a8 00 00 00       	add    $0xa8,%eax
801034fb:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80103502:	00 
80103503:	89 04 24             	mov    %eax,(%esp)
80103506:	e8 cf fe ff ff       	call   801033da <xchg>
  scheduler();     // start running processes
8010350b:	e8 2e 11 00 00       	call   8010463e <scheduler>

80103510 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80103510:	55                   	push   %ebp
80103511:	89 e5                	mov    %esp,%ebp
80103513:	53                   	push   %ebx
80103514:	83 ec 24             	sub    $0x24,%esp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
80103517:	c7 04 24 00 70 00 00 	movl   $0x7000,(%esp)
8010351e:	e8 aa fe ff ff       	call   801033cd <p2v>
80103523:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80103526:	b8 8a 00 00 00       	mov    $0x8a,%eax
8010352b:	89 44 24 08          	mov    %eax,0x8(%esp)
8010352f:	c7 44 24 04 0c b5 10 	movl   $0x8010b50c,0x4(%esp)
80103536:	80 
80103537:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010353a:	89 04 24             	mov    %eax,(%esp)
8010353d:	e8 a3 18 00 00       	call   80104de5 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80103542:	c7 45 f4 20 f9 10 80 	movl   $0x8010f920,-0xc(%ebp)
80103549:	e9 86 00 00 00       	jmp    801035d4 <startothers+0xc4>
    if(c == cpus+cpunum())  // We've started already.
8010354e:	e8 32 f9 ff ff       	call   80102e85 <cpunum>
80103553:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103559:	05 20 f9 10 80       	add    $0x8010f920,%eax
8010355e:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103561:	74 69                	je     801035cc <startothers+0xbc>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what 
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
80103563:	e8 8f f5 ff ff       	call   80102af7 <kalloc>
80103568:	89 45 ec             	mov    %eax,-0x14(%ebp)
    *(void**)(code-4) = stack + KSTACKSIZE;
8010356b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010356e:	83 e8 04             	sub    $0x4,%eax
80103571:	8b 55 ec             	mov    -0x14(%ebp),%edx
80103574:	81 c2 00 10 00 00    	add    $0x1000,%edx
8010357a:	89 10                	mov    %edx,(%eax)
    *(void**)(code-8) = mpenter;
8010357c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010357f:	83 e8 08             	sub    $0x8,%eax
80103582:	c7 00 af 34 10 80    	movl   $0x801034af,(%eax)
    *(int**)(code-12) = (void *) v2p(entrypgdir);
80103588:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010358b:	8d 58 f4             	lea    -0xc(%eax),%ebx
8010358e:	c7 04 24 00 a0 10 80 	movl   $0x8010a000,(%esp)
80103595:	e8 26 fe ff ff       	call   801033c0 <v2p>
8010359a:	89 03                	mov    %eax,(%ebx)

    lapicstartap(c->id, v2p(code));
8010359c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010359f:	89 04 24             	mov    %eax,(%esp)
801035a2:	e8 19 fe ff ff       	call   801033c0 <v2p>
801035a7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801035aa:	0f b6 12             	movzbl (%edx),%edx
801035ad:	0f b6 d2             	movzbl %dl,%edx
801035b0:	89 44 24 04          	mov    %eax,0x4(%esp)
801035b4:	89 14 24             	mov    %edx,(%esp)
801035b7:	e8 4f f9 ff ff       	call   80102f0b <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
801035bc:	90                   	nop
801035bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801035c0:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
801035c6:	85 c0                	test   %eax,%eax
801035c8:	74 f3                	je     801035bd <startothers+0xad>
801035ca:	eb 01                	jmp    801035cd <startothers+0xbd>
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
    if(c == cpus+cpunum())  // We've started already.
      continue;
801035cc:	90                   	nop
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
801035cd:	81 45 f4 bc 00 00 00 	addl   $0xbc,-0xc(%ebp)
801035d4:	a1 00 ff 10 80       	mov    0x8010ff00,%eax
801035d9:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801035df:	05 20 f9 10 80       	add    $0x8010f920,%eax
801035e4:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801035e7:	0f 87 61 ff ff ff    	ja     8010354e <startothers+0x3e>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
      ;
  }
}
801035ed:	83 c4 24             	add    $0x24,%esp
801035f0:	5b                   	pop    %ebx
801035f1:	5d                   	pop    %ebp
801035f2:	c3                   	ret    
	...

801035f4 <p2v>:
801035f4:	55                   	push   %ebp
801035f5:	89 e5                	mov    %esp,%ebp
801035f7:	8b 45 08             	mov    0x8(%ebp),%eax
801035fa:	05 00 00 00 80       	add    $0x80000000,%eax
801035ff:	5d                   	pop    %ebp
80103600:	c3                   	ret    

80103601 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80103601:	55                   	push   %ebp
80103602:	89 e5                	mov    %esp,%ebp
80103604:	53                   	push   %ebx
80103605:	83 ec 14             	sub    $0x14,%esp
80103608:	8b 45 08             	mov    0x8(%ebp),%eax
8010360b:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010360f:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80103613:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80103617:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
8010361b:	ec                   	in     (%dx),%al
8010361c:	89 c3                	mov    %eax,%ebx
8010361e:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80103621:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80103625:	83 c4 14             	add    $0x14,%esp
80103628:	5b                   	pop    %ebx
80103629:	5d                   	pop    %ebp
8010362a:	c3                   	ret    

8010362b <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
8010362b:	55                   	push   %ebp
8010362c:	89 e5                	mov    %esp,%ebp
8010362e:	83 ec 08             	sub    $0x8,%esp
80103631:	8b 55 08             	mov    0x8(%ebp),%edx
80103634:	8b 45 0c             	mov    0xc(%ebp),%eax
80103637:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
8010363b:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010363e:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103642:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103646:	ee                   	out    %al,(%dx)
}
80103647:	c9                   	leave  
80103648:	c3                   	ret    

80103649 <mpbcpu>:
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
80103649:	55                   	push   %ebp
8010364a:	89 e5                	mov    %esp,%ebp
  return bcpu-cpus;
8010364c:	a1 44 b6 10 80       	mov    0x8010b644,%eax
80103651:	89 c2                	mov    %eax,%edx
80103653:	b8 20 f9 10 80       	mov    $0x8010f920,%eax
80103658:	89 d1                	mov    %edx,%ecx
8010365a:	29 c1                	sub    %eax,%ecx
8010365c:	89 c8                	mov    %ecx,%eax
8010365e:	c1 f8 02             	sar    $0x2,%eax
80103661:	69 c0 cf 46 7d 67    	imul   $0x677d46cf,%eax,%eax
}
80103667:	5d                   	pop    %ebp
80103668:	c3                   	ret    

80103669 <sum>:

static uchar
sum(uchar *addr, int len)
{
80103669:	55                   	push   %ebp
8010366a:	89 e5                	mov    %esp,%ebp
8010366c:	83 ec 10             	sub    $0x10,%esp
  int i, sum;
  
  sum = 0;
8010366f:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  for(i=0; i<len; i++)
80103676:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
8010367d:	eb 13                	jmp    80103692 <sum+0x29>
    sum += addr[i];
8010367f:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103682:	03 45 08             	add    0x8(%ebp),%eax
80103685:	0f b6 00             	movzbl (%eax),%eax
80103688:	0f b6 c0             	movzbl %al,%eax
8010368b:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
8010368e:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80103692:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103695:	3b 45 0c             	cmp    0xc(%ebp),%eax
80103698:	7c e5                	jl     8010367f <sum+0x16>
    sum += addr[i];
  return sum;
8010369a:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
8010369d:	c9                   	leave  
8010369e:	c3                   	ret    

8010369f <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
8010369f:	55                   	push   %ebp
801036a0:	89 e5                	mov    %esp,%ebp
801036a2:	83 ec 28             	sub    $0x28,%esp
  uchar *e, *p, *addr;

  addr = p2v(a);
801036a5:	8b 45 08             	mov    0x8(%ebp),%eax
801036a8:	89 04 24             	mov    %eax,(%esp)
801036ab:	e8 44 ff ff ff       	call   801035f4 <p2v>
801036b0:	89 45 f0             	mov    %eax,-0x10(%ebp)
  e = addr+len;
801036b3:	8b 45 0c             	mov    0xc(%ebp),%eax
801036b6:	03 45 f0             	add    -0x10(%ebp),%eax
801036b9:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(p = addr; p < e; p += sizeof(struct mp))
801036bc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801036bf:	89 45 f4             	mov    %eax,-0xc(%ebp)
801036c2:	eb 3f                	jmp    80103703 <mpsearch1+0x64>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
801036c4:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
801036cb:	00 
801036cc:	c7 44 24 04 e0 82 10 	movl   $0x801082e0,0x4(%esp)
801036d3:	80 
801036d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801036d7:	89 04 24             	mov    %eax,(%esp)
801036da:	e8 aa 16 00 00       	call   80104d89 <memcmp>
801036df:	85 c0                	test   %eax,%eax
801036e1:	75 1c                	jne    801036ff <mpsearch1+0x60>
801036e3:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
801036ea:	00 
801036eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801036ee:	89 04 24             	mov    %eax,(%esp)
801036f1:	e8 73 ff ff ff       	call   80103669 <sum>
801036f6:	84 c0                	test   %al,%al
801036f8:	75 05                	jne    801036ff <mpsearch1+0x60>
      return (struct mp*)p;
801036fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801036fd:	eb 11                	jmp    80103710 <mpsearch1+0x71>
{
  uchar *e, *p, *addr;

  addr = p2v(a);
  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
801036ff:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80103703:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103706:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103709:	72 b9                	jb     801036c4 <mpsearch1+0x25>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
8010370b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103710:	c9                   	leave  
80103711:	c3                   	ret    

80103712 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80103712:	55                   	push   %ebp
80103713:	89 e5                	mov    %esp,%ebp
80103715:	83 ec 28             	sub    $0x28,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
80103718:	c7 45 f4 00 04 00 80 	movl   $0x80000400,-0xc(%ebp)
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
8010371f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103722:	83 c0 0f             	add    $0xf,%eax
80103725:	0f b6 00             	movzbl (%eax),%eax
80103728:	0f b6 c0             	movzbl %al,%eax
8010372b:	89 c2                	mov    %eax,%edx
8010372d:	c1 e2 08             	shl    $0x8,%edx
80103730:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103733:	83 c0 0e             	add    $0xe,%eax
80103736:	0f b6 00             	movzbl (%eax),%eax
80103739:	0f b6 c0             	movzbl %al,%eax
8010373c:	09 d0                	or     %edx,%eax
8010373e:	c1 e0 04             	shl    $0x4,%eax
80103741:	89 45 f0             	mov    %eax,-0x10(%ebp)
80103744:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103748:	74 21                	je     8010376b <mpsearch+0x59>
    if((mp = mpsearch1(p, 1024)))
8010374a:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80103751:	00 
80103752:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103755:	89 04 24             	mov    %eax,(%esp)
80103758:	e8 42 ff ff ff       	call   8010369f <mpsearch1>
8010375d:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103760:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103764:	74 50                	je     801037b6 <mpsearch+0xa4>
      return mp;
80103766:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103769:	eb 5f                	jmp    801037ca <mpsearch+0xb8>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
8010376b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010376e:	83 c0 14             	add    $0x14,%eax
80103771:	0f b6 00             	movzbl (%eax),%eax
80103774:	0f b6 c0             	movzbl %al,%eax
80103777:	89 c2                	mov    %eax,%edx
80103779:	c1 e2 08             	shl    $0x8,%edx
8010377c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010377f:	83 c0 13             	add    $0x13,%eax
80103782:	0f b6 00             	movzbl (%eax),%eax
80103785:	0f b6 c0             	movzbl %al,%eax
80103788:	09 d0                	or     %edx,%eax
8010378a:	c1 e0 0a             	shl    $0xa,%eax
8010378d:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((mp = mpsearch1(p-1024, 1024)))
80103790:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103793:	2d 00 04 00 00       	sub    $0x400,%eax
80103798:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
8010379f:	00 
801037a0:	89 04 24             	mov    %eax,(%esp)
801037a3:	e8 f7 fe ff ff       	call   8010369f <mpsearch1>
801037a8:	89 45 ec             	mov    %eax,-0x14(%ebp)
801037ab:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801037af:	74 05                	je     801037b6 <mpsearch+0xa4>
      return mp;
801037b1:	8b 45 ec             	mov    -0x14(%ebp),%eax
801037b4:	eb 14                	jmp    801037ca <mpsearch+0xb8>
  }
  return mpsearch1(0xF0000, 0x10000);
801037b6:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
801037bd:	00 
801037be:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
801037c5:	e8 d5 fe ff ff       	call   8010369f <mpsearch1>
}
801037ca:	c9                   	leave  
801037cb:	c3                   	ret    

801037cc <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
801037cc:	55                   	push   %ebp
801037cd:	89 e5                	mov    %esp,%ebp
801037cf:	83 ec 28             	sub    $0x28,%esp
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
801037d2:	e8 3b ff ff ff       	call   80103712 <mpsearch>
801037d7:	89 45 f4             	mov    %eax,-0xc(%ebp)
801037da:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801037de:	74 0a                	je     801037ea <mpconfig+0x1e>
801037e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801037e3:	8b 40 04             	mov    0x4(%eax),%eax
801037e6:	85 c0                	test   %eax,%eax
801037e8:	75 0a                	jne    801037f4 <mpconfig+0x28>
    return 0;
801037ea:	b8 00 00 00 00       	mov    $0x0,%eax
801037ef:	e9 83 00 00 00       	jmp    80103877 <mpconfig+0xab>
  conf = (struct mpconf*) p2v((uint) mp->physaddr);
801037f4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801037f7:	8b 40 04             	mov    0x4(%eax),%eax
801037fa:	89 04 24             	mov    %eax,(%esp)
801037fd:	e8 f2 fd ff ff       	call   801035f4 <p2v>
80103802:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(memcmp(conf, "PCMP", 4) != 0)
80103805:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
8010380c:	00 
8010380d:	c7 44 24 04 e5 82 10 	movl   $0x801082e5,0x4(%esp)
80103814:	80 
80103815:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103818:	89 04 24             	mov    %eax,(%esp)
8010381b:	e8 69 15 00 00       	call   80104d89 <memcmp>
80103820:	85 c0                	test   %eax,%eax
80103822:	74 07                	je     8010382b <mpconfig+0x5f>
    return 0;
80103824:	b8 00 00 00 00       	mov    $0x0,%eax
80103829:	eb 4c                	jmp    80103877 <mpconfig+0xab>
  if(conf->version != 1 && conf->version != 4)
8010382b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010382e:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80103832:	3c 01                	cmp    $0x1,%al
80103834:	74 12                	je     80103848 <mpconfig+0x7c>
80103836:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103839:	0f b6 40 06          	movzbl 0x6(%eax),%eax
8010383d:	3c 04                	cmp    $0x4,%al
8010383f:	74 07                	je     80103848 <mpconfig+0x7c>
    return 0;
80103841:	b8 00 00 00 00       	mov    $0x0,%eax
80103846:	eb 2f                	jmp    80103877 <mpconfig+0xab>
  if(sum((uchar*)conf, conf->length) != 0)
80103848:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010384b:	0f b7 40 04          	movzwl 0x4(%eax),%eax
8010384f:	0f b7 c0             	movzwl %ax,%eax
80103852:	89 44 24 04          	mov    %eax,0x4(%esp)
80103856:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103859:	89 04 24             	mov    %eax,(%esp)
8010385c:	e8 08 fe ff ff       	call   80103669 <sum>
80103861:	84 c0                	test   %al,%al
80103863:	74 07                	je     8010386c <mpconfig+0xa0>
    return 0;
80103865:	b8 00 00 00 00       	mov    $0x0,%eax
8010386a:	eb 0b                	jmp    80103877 <mpconfig+0xab>
  *pmp = mp;
8010386c:	8b 45 08             	mov    0x8(%ebp),%eax
8010386f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103872:	89 10                	mov    %edx,(%eax)
  return conf;
80103874:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80103877:	c9                   	leave  
80103878:	c3                   	ret    

80103879 <mpinit>:

void
mpinit(void)
{
80103879:	55                   	push   %ebp
8010387a:	89 e5                	mov    %esp,%ebp
8010387c:	83 ec 38             	sub    $0x38,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
8010387f:	c7 05 44 b6 10 80 20 	movl   $0x8010f920,0x8010b644
80103886:	f9 10 80 
  if((conf = mpconfig(&mp)) == 0)
80103889:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010388c:	89 04 24             	mov    %eax,(%esp)
8010388f:	e8 38 ff ff ff       	call   801037cc <mpconfig>
80103894:	89 45 f0             	mov    %eax,-0x10(%ebp)
80103897:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010389b:	0f 84 9c 01 00 00    	je     80103a3d <mpinit+0x1c4>
    return;
  ismp = 1;
801038a1:	c7 05 04 f9 10 80 01 	movl   $0x1,0x8010f904
801038a8:	00 00 00 
  lapic = (uint*)conf->lapicaddr;
801038ab:	8b 45 f0             	mov    -0x10(%ebp),%eax
801038ae:	8b 40 24             	mov    0x24(%eax),%eax
801038b1:	a3 7c f8 10 80       	mov    %eax,0x8010f87c
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
801038b6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801038b9:	83 c0 2c             	add    $0x2c,%eax
801038bc:	89 45 f4             	mov    %eax,-0xc(%ebp)
801038bf:	8b 45 f0             	mov    -0x10(%ebp),%eax
801038c2:	0f b7 40 04          	movzwl 0x4(%eax),%eax
801038c6:	0f b7 c0             	movzwl %ax,%eax
801038c9:	03 45 f0             	add    -0x10(%ebp),%eax
801038cc:	89 45 ec             	mov    %eax,-0x14(%ebp)
801038cf:	e9 f4 00 00 00       	jmp    801039c8 <mpinit+0x14f>
    switch(*p){
801038d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801038d7:	0f b6 00             	movzbl (%eax),%eax
801038da:	0f b6 c0             	movzbl %al,%eax
801038dd:	83 f8 04             	cmp    $0x4,%eax
801038e0:	0f 87 bf 00 00 00    	ja     801039a5 <mpinit+0x12c>
801038e6:	8b 04 85 28 83 10 80 	mov    -0x7fef7cd8(,%eax,4),%eax
801038ed:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
801038ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
801038f2:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(ncpu != proc->apicid){
801038f5:	8b 45 e8             	mov    -0x18(%ebp),%eax
801038f8:	0f b6 40 01          	movzbl 0x1(%eax),%eax
801038fc:	0f b6 d0             	movzbl %al,%edx
801038ff:	a1 00 ff 10 80       	mov    0x8010ff00,%eax
80103904:	39 c2                	cmp    %eax,%edx
80103906:	74 2d                	je     80103935 <mpinit+0xbc>
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
80103908:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010390b:	0f b6 40 01          	movzbl 0x1(%eax),%eax
8010390f:	0f b6 d0             	movzbl %al,%edx
80103912:	a1 00 ff 10 80       	mov    0x8010ff00,%eax
80103917:	89 54 24 08          	mov    %edx,0x8(%esp)
8010391b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010391f:	c7 04 24 ea 82 10 80 	movl   $0x801082ea,(%esp)
80103926:	e8 76 ca ff ff       	call   801003a1 <cprintf>
        ismp = 0;
8010392b:	c7 05 04 f9 10 80 00 	movl   $0x0,0x8010f904
80103932:	00 00 00 
      }
      if(proc->flags & MPBOOT)
80103935:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103938:	0f b6 40 03          	movzbl 0x3(%eax),%eax
8010393c:	0f b6 c0             	movzbl %al,%eax
8010393f:	83 e0 02             	and    $0x2,%eax
80103942:	85 c0                	test   %eax,%eax
80103944:	74 15                	je     8010395b <mpinit+0xe2>
        bcpu = &cpus[ncpu];
80103946:	a1 00 ff 10 80       	mov    0x8010ff00,%eax
8010394b:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103951:	05 20 f9 10 80       	add    $0x8010f920,%eax
80103956:	a3 44 b6 10 80       	mov    %eax,0x8010b644
      cpus[ncpu].id = ncpu;
8010395b:	8b 15 00 ff 10 80    	mov    0x8010ff00,%edx
80103961:	a1 00 ff 10 80       	mov    0x8010ff00,%eax
80103966:	69 d2 bc 00 00 00    	imul   $0xbc,%edx,%edx
8010396c:	81 c2 20 f9 10 80    	add    $0x8010f920,%edx
80103972:	88 02                	mov    %al,(%edx)
      ncpu++;
80103974:	a1 00 ff 10 80       	mov    0x8010ff00,%eax
80103979:	83 c0 01             	add    $0x1,%eax
8010397c:	a3 00 ff 10 80       	mov    %eax,0x8010ff00
      p += sizeof(struct mpproc);
80103981:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
      continue;
80103985:	eb 41                	jmp    801039c8 <mpinit+0x14f>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
80103987:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010398a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      ioapicid = ioapic->apicno;
8010398d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80103990:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103994:	a2 00 f9 10 80       	mov    %al,0x8010f900
      p += sizeof(struct mpioapic);
80103999:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
8010399d:	eb 29                	jmp    801039c8 <mpinit+0x14f>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
8010399f:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
801039a3:	eb 23                	jmp    801039c8 <mpinit+0x14f>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
801039a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039a8:	0f b6 00             	movzbl (%eax),%eax
801039ab:	0f b6 c0             	movzbl %al,%eax
801039ae:	89 44 24 04          	mov    %eax,0x4(%esp)
801039b2:	c7 04 24 08 83 10 80 	movl   $0x80108308,(%esp)
801039b9:	e8 e3 c9 ff ff       	call   801003a1 <cprintf>
      ismp = 0;
801039be:	c7 05 04 f9 10 80 00 	movl   $0x0,0x8010f904
801039c5:	00 00 00 
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
801039c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039cb:	3b 45 ec             	cmp    -0x14(%ebp),%eax
801039ce:	0f 82 00 ff ff ff    	jb     801038d4 <mpinit+0x5b>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
      ismp = 0;
    }
  }
  if(!ismp){
801039d4:	a1 04 f9 10 80       	mov    0x8010f904,%eax
801039d9:	85 c0                	test   %eax,%eax
801039db:	75 1d                	jne    801039fa <mpinit+0x181>
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
801039dd:	c7 05 00 ff 10 80 01 	movl   $0x1,0x8010ff00
801039e4:	00 00 00 
    lapic = 0;
801039e7:	c7 05 7c f8 10 80 00 	movl   $0x0,0x8010f87c
801039ee:	00 00 00 
    ioapicid = 0;
801039f1:	c6 05 00 f9 10 80 00 	movb   $0x0,0x8010f900
    return;
801039f8:	eb 44                	jmp    80103a3e <mpinit+0x1c5>
  }

  if(mp->imcrp){
801039fa:	8b 45 e0             	mov    -0x20(%ebp),%eax
801039fd:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
80103a01:	84 c0                	test   %al,%al
80103a03:	74 39                	je     80103a3e <mpinit+0x1c5>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
80103a05:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
80103a0c:	00 
80103a0d:	c7 04 24 22 00 00 00 	movl   $0x22,(%esp)
80103a14:	e8 12 fc ff ff       	call   8010362b <outb>
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80103a19:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80103a20:	e8 dc fb ff ff       	call   80103601 <inb>
80103a25:	83 c8 01             	or     $0x1,%eax
80103a28:	0f b6 c0             	movzbl %al,%eax
80103a2b:	89 44 24 04          	mov    %eax,0x4(%esp)
80103a2f:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80103a36:	e8 f0 fb ff ff       	call   8010362b <outb>
80103a3b:	eb 01                	jmp    80103a3e <mpinit+0x1c5>
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
80103a3d:	90                   	nop
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
  }
}
80103a3e:	c9                   	leave  
80103a3f:	c3                   	ret    

80103a40 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103a40:	55                   	push   %ebp
80103a41:	89 e5                	mov    %esp,%ebp
80103a43:	83 ec 08             	sub    $0x8,%esp
80103a46:	8b 55 08             	mov    0x8(%ebp),%edx
80103a49:	8b 45 0c             	mov    0xc(%ebp),%eax
80103a4c:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103a50:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103a53:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103a57:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103a5b:	ee                   	out    %al,(%dx)
}
80103a5c:	c9                   	leave  
80103a5d:	c3                   	ret    

80103a5e <picsetmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static ushort irqmask = 0xFFFF & ~(1<<IRQ_SLAVE);

static void
picsetmask(ushort mask)
{
80103a5e:	55                   	push   %ebp
80103a5f:	89 e5                	mov    %esp,%ebp
80103a61:	83 ec 0c             	sub    $0xc,%esp
80103a64:	8b 45 08             	mov    0x8(%ebp),%eax
80103a67:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  irqmask = mask;
80103a6b:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103a6f:	66 a3 00 b0 10 80    	mov    %ax,0x8010b000
  outb(IO_PIC1+1, mask);
80103a75:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103a79:	0f b6 c0             	movzbl %al,%eax
80103a7c:	89 44 24 04          	mov    %eax,0x4(%esp)
80103a80:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103a87:	e8 b4 ff ff ff       	call   80103a40 <outb>
  outb(IO_PIC2+1, mask >> 8);
80103a8c:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103a90:	66 c1 e8 08          	shr    $0x8,%ax
80103a94:	0f b6 c0             	movzbl %al,%eax
80103a97:	89 44 24 04          	mov    %eax,0x4(%esp)
80103a9b:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103aa2:	e8 99 ff ff ff       	call   80103a40 <outb>
}
80103aa7:	c9                   	leave  
80103aa8:	c3                   	ret    

80103aa9 <picenable>:

void
picenable(int irq)
{
80103aa9:	55                   	push   %ebp
80103aaa:	89 e5                	mov    %esp,%ebp
80103aac:	53                   	push   %ebx
80103aad:	83 ec 04             	sub    $0x4,%esp
  picsetmask(irqmask & ~(1<<irq));
80103ab0:	8b 45 08             	mov    0x8(%ebp),%eax
80103ab3:	ba 01 00 00 00       	mov    $0x1,%edx
80103ab8:	89 d3                	mov    %edx,%ebx
80103aba:	89 c1                	mov    %eax,%ecx
80103abc:	d3 e3                	shl    %cl,%ebx
80103abe:	89 d8                	mov    %ebx,%eax
80103ac0:	89 c2                	mov    %eax,%edx
80103ac2:	f7 d2                	not    %edx
80103ac4:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
80103acb:	21 d0                	and    %edx,%eax
80103acd:	0f b7 c0             	movzwl %ax,%eax
80103ad0:	89 04 24             	mov    %eax,(%esp)
80103ad3:	e8 86 ff ff ff       	call   80103a5e <picsetmask>
}
80103ad8:	83 c4 04             	add    $0x4,%esp
80103adb:	5b                   	pop    %ebx
80103adc:	5d                   	pop    %ebp
80103add:	c3                   	ret    

80103ade <picinit>:

// Initialize the 8259A interrupt controllers.
void
picinit(void)
{
80103ade:	55                   	push   %ebp
80103adf:	89 e5                	mov    %esp,%ebp
80103ae1:	83 ec 08             	sub    $0x8,%esp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
80103ae4:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80103aeb:	00 
80103aec:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103af3:	e8 48 ff ff ff       	call   80103a40 <outb>
  outb(IO_PIC2+1, 0xFF);
80103af8:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80103aff:	00 
80103b00:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103b07:	e8 34 ff ff ff       	call   80103a40 <outb>

  // ICW1:  0001g0hi
  //    g:  0 = edge triggering, 1 = level triggering
  //    h:  0 = cascaded PICs, 1 = master only
  //    i:  0 = no ICW4, 1 = ICW4 required
  outb(IO_PIC1, 0x11);
80103b0c:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80103b13:	00 
80103b14:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103b1b:	e8 20 ff ff ff       	call   80103a40 <outb>

  // ICW2:  Vector offset
  outb(IO_PIC1+1, T_IRQ0);
80103b20:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
80103b27:	00 
80103b28:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103b2f:	e8 0c ff ff ff       	call   80103a40 <outb>

  // ICW3:  (master PIC) bit mask of IR lines connected to slaves
  //        (slave PIC) 3-bit # of slave's connection to master
  outb(IO_PIC1+1, 1<<IRQ_SLAVE);
80103b34:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
80103b3b:	00 
80103b3c:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103b43:	e8 f8 fe ff ff       	call   80103a40 <outb>
  //    m:  0 = slave PIC, 1 = master PIC
  //      (ignored when b is 0, as the master/slave role
  //      can be hardwired).
  //    a:  1 = Automatic EOI mode
  //    p:  0 = MCS-80/85 mode, 1 = intel x86 mode
  outb(IO_PIC1+1, 0x3);
80103b48:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80103b4f:	00 
80103b50:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103b57:	e8 e4 fe ff ff       	call   80103a40 <outb>

  // Set up slave (8259A-2)
  outb(IO_PIC2, 0x11);                  // ICW1
80103b5c:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80103b63:	00 
80103b64:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103b6b:	e8 d0 fe ff ff       	call   80103a40 <outb>
  outb(IO_PIC2+1, T_IRQ0 + 8);      // ICW2
80103b70:	c7 44 24 04 28 00 00 	movl   $0x28,0x4(%esp)
80103b77:	00 
80103b78:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103b7f:	e8 bc fe ff ff       	call   80103a40 <outb>
  outb(IO_PIC2+1, IRQ_SLAVE);           // ICW3
80103b84:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80103b8b:	00 
80103b8c:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103b93:	e8 a8 fe ff ff       	call   80103a40 <outb>
  // NB Automatic EOI mode doesn't tend to work on the slave.
  // Linux source code says it's "to be investigated".
  outb(IO_PIC2+1, 0x3);                 // ICW4
80103b98:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80103b9f:	00 
80103ba0:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103ba7:	e8 94 fe ff ff       	call   80103a40 <outb>

  // OCW3:  0ef01prs
  //   ef:  0x = NOP, 10 = clear specific mask, 11 = set specific mask
  //    p:  0 = no polling, 1 = polling mode
  //   rs:  0x = NOP, 10 = read IRR, 11 = read ISR
  outb(IO_PIC1, 0x68);             // clear specific mask
80103bac:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80103bb3:	00 
80103bb4:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103bbb:	e8 80 fe ff ff       	call   80103a40 <outb>
  outb(IO_PIC1, 0x0a);             // read IRR by default
80103bc0:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80103bc7:	00 
80103bc8:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103bcf:	e8 6c fe ff ff       	call   80103a40 <outb>

  outb(IO_PIC2, 0x68);             // OCW3
80103bd4:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80103bdb:	00 
80103bdc:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103be3:	e8 58 fe ff ff       	call   80103a40 <outb>
  outb(IO_PIC2, 0x0a);             // OCW3
80103be8:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80103bef:	00 
80103bf0:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103bf7:	e8 44 fe ff ff       	call   80103a40 <outb>

  if(irqmask != 0xFFFF)
80103bfc:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
80103c03:	66 83 f8 ff          	cmp    $0xffff,%ax
80103c07:	74 12                	je     80103c1b <picinit+0x13d>
    picsetmask(irqmask);
80103c09:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
80103c10:	0f b7 c0             	movzwl %ax,%eax
80103c13:	89 04 24             	mov    %eax,(%esp)
80103c16:	e8 43 fe ff ff       	call   80103a5e <picsetmask>
}
80103c1b:	c9                   	leave  
80103c1c:	c3                   	ret    
80103c1d:	00 00                	add    %al,(%eax)
	...

80103c20 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80103c20:	55                   	push   %ebp
80103c21:	89 e5                	mov    %esp,%ebp
80103c23:	83 ec 28             	sub    $0x28,%esp
  struct pipe *p;

  p = 0;
80103c26:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  *f0 = *f1 = 0;
80103c2d:	8b 45 0c             	mov    0xc(%ebp),%eax
80103c30:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
80103c36:	8b 45 0c             	mov    0xc(%ebp),%eax
80103c39:	8b 10                	mov    (%eax),%edx
80103c3b:	8b 45 08             	mov    0x8(%ebp),%eax
80103c3e:	89 10                	mov    %edx,(%eax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80103c40:	e8 cf d2 ff ff       	call   80100f14 <filealloc>
80103c45:	8b 55 08             	mov    0x8(%ebp),%edx
80103c48:	89 02                	mov    %eax,(%edx)
80103c4a:	8b 45 08             	mov    0x8(%ebp),%eax
80103c4d:	8b 00                	mov    (%eax),%eax
80103c4f:	85 c0                	test   %eax,%eax
80103c51:	0f 84 c8 00 00 00    	je     80103d1f <pipealloc+0xff>
80103c57:	e8 b8 d2 ff ff       	call   80100f14 <filealloc>
80103c5c:	8b 55 0c             	mov    0xc(%ebp),%edx
80103c5f:	89 02                	mov    %eax,(%edx)
80103c61:	8b 45 0c             	mov    0xc(%ebp),%eax
80103c64:	8b 00                	mov    (%eax),%eax
80103c66:	85 c0                	test   %eax,%eax
80103c68:	0f 84 b1 00 00 00    	je     80103d1f <pipealloc+0xff>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
80103c6e:	e8 84 ee ff ff       	call   80102af7 <kalloc>
80103c73:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103c76:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103c7a:	0f 84 9e 00 00 00    	je     80103d1e <pipealloc+0xfe>
    goto bad;
  p->readopen = 1;
80103c80:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c83:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80103c8a:	00 00 00 
  p->writeopen = 1;
80103c8d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c90:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80103c97:	00 00 00 
  p->nwrite = 0;
80103c9a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c9d:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80103ca4:	00 00 00 
  p->nread = 0;
80103ca7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103caa:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80103cb1:	00 00 00 
  initlock(&p->lock, "pipe");
80103cb4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103cb7:	c7 44 24 04 3c 83 10 	movl   $0x8010833c,0x4(%esp)
80103cbe:	80 
80103cbf:	89 04 24             	mov    %eax,(%esp)
80103cc2:	e8 db 0d 00 00       	call   80104aa2 <initlock>
  (*f0)->type = FD_PIPE;
80103cc7:	8b 45 08             	mov    0x8(%ebp),%eax
80103cca:	8b 00                	mov    (%eax),%eax
80103ccc:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80103cd2:	8b 45 08             	mov    0x8(%ebp),%eax
80103cd5:	8b 00                	mov    (%eax),%eax
80103cd7:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80103cdb:	8b 45 08             	mov    0x8(%ebp),%eax
80103cde:	8b 00                	mov    (%eax),%eax
80103ce0:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80103ce4:	8b 45 08             	mov    0x8(%ebp),%eax
80103ce7:	8b 00                	mov    (%eax),%eax
80103ce9:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103cec:	89 50 0c             	mov    %edx,0xc(%eax)
  (*f1)->type = FD_PIPE;
80103cef:	8b 45 0c             	mov    0xc(%ebp),%eax
80103cf2:	8b 00                	mov    (%eax),%eax
80103cf4:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80103cfa:	8b 45 0c             	mov    0xc(%ebp),%eax
80103cfd:	8b 00                	mov    (%eax),%eax
80103cff:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80103d03:	8b 45 0c             	mov    0xc(%ebp),%eax
80103d06:	8b 00                	mov    (%eax),%eax
80103d08:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80103d0c:	8b 45 0c             	mov    0xc(%ebp),%eax
80103d0f:	8b 00                	mov    (%eax),%eax
80103d11:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103d14:	89 50 0c             	mov    %edx,0xc(%eax)
  return 0;
80103d17:	b8 00 00 00 00       	mov    $0x0,%eax
80103d1c:	eb 43                	jmp    80103d61 <pipealloc+0x141>
  p = 0;
  *f0 = *f1 = 0;
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
    goto bad;
80103d1e:	90                   	nop
  (*f1)->pipe = p;
  return 0;

//PAGEBREAK: 20
 bad:
  if(p)
80103d1f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103d23:	74 0b                	je     80103d30 <pipealloc+0x110>
    kfree((char*)p);
80103d25:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d28:	89 04 24             	mov    %eax,(%esp)
80103d2b:	e8 2e ed ff ff       	call   80102a5e <kfree>
  if(*f0)
80103d30:	8b 45 08             	mov    0x8(%ebp),%eax
80103d33:	8b 00                	mov    (%eax),%eax
80103d35:	85 c0                	test   %eax,%eax
80103d37:	74 0d                	je     80103d46 <pipealloc+0x126>
    fileclose(*f0);
80103d39:	8b 45 08             	mov    0x8(%ebp),%eax
80103d3c:	8b 00                	mov    (%eax),%eax
80103d3e:	89 04 24             	mov    %eax,(%esp)
80103d41:	e8 76 d2 ff ff       	call   80100fbc <fileclose>
  if(*f1)
80103d46:	8b 45 0c             	mov    0xc(%ebp),%eax
80103d49:	8b 00                	mov    (%eax),%eax
80103d4b:	85 c0                	test   %eax,%eax
80103d4d:	74 0d                	je     80103d5c <pipealloc+0x13c>
    fileclose(*f1);
80103d4f:	8b 45 0c             	mov    0xc(%ebp),%eax
80103d52:	8b 00                	mov    (%eax),%eax
80103d54:	89 04 24             	mov    %eax,(%esp)
80103d57:	e8 60 d2 ff ff       	call   80100fbc <fileclose>
  return -1;
80103d5c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80103d61:	c9                   	leave  
80103d62:	c3                   	ret    

80103d63 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80103d63:	55                   	push   %ebp
80103d64:	89 e5                	mov    %esp,%ebp
80103d66:	83 ec 18             	sub    $0x18,%esp
  acquire(&p->lock);
80103d69:	8b 45 08             	mov    0x8(%ebp),%eax
80103d6c:	89 04 24             	mov    %eax,(%esp)
80103d6f:	e8 4f 0d 00 00       	call   80104ac3 <acquire>
  if(writable){
80103d74:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80103d78:	74 1f                	je     80103d99 <pipeclose+0x36>
    p->writeopen = 0;
80103d7a:	8b 45 08             	mov    0x8(%ebp),%eax
80103d7d:	c7 80 40 02 00 00 00 	movl   $0x0,0x240(%eax)
80103d84:	00 00 00 
    wakeup(&p->nread);
80103d87:	8b 45 08             	mov    0x8(%ebp),%eax
80103d8a:	05 34 02 00 00       	add    $0x234,%eax
80103d8f:	89 04 24             	mov    %eax,(%esp)
80103d92:	e8 29 0b 00 00       	call   801048c0 <wakeup>
80103d97:	eb 1d                	jmp    80103db6 <pipeclose+0x53>
  } else {
    p->readopen = 0;
80103d99:	8b 45 08             	mov    0x8(%ebp),%eax
80103d9c:	c7 80 3c 02 00 00 00 	movl   $0x0,0x23c(%eax)
80103da3:	00 00 00 
    wakeup(&p->nwrite);
80103da6:	8b 45 08             	mov    0x8(%ebp),%eax
80103da9:	05 38 02 00 00       	add    $0x238,%eax
80103dae:	89 04 24             	mov    %eax,(%esp)
80103db1:	e8 0a 0b 00 00       	call   801048c0 <wakeup>
  }
  if(p->readopen == 0 && p->writeopen == 0){
80103db6:	8b 45 08             	mov    0x8(%ebp),%eax
80103db9:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80103dbf:	85 c0                	test   %eax,%eax
80103dc1:	75 25                	jne    80103de8 <pipeclose+0x85>
80103dc3:	8b 45 08             	mov    0x8(%ebp),%eax
80103dc6:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80103dcc:	85 c0                	test   %eax,%eax
80103dce:	75 18                	jne    80103de8 <pipeclose+0x85>
    release(&p->lock);
80103dd0:	8b 45 08             	mov    0x8(%ebp),%eax
80103dd3:	89 04 24             	mov    %eax,(%esp)
80103dd6:	e8 4a 0d 00 00       	call   80104b25 <release>
    kfree((char*)p);
80103ddb:	8b 45 08             	mov    0x8(%ebp),%eax
80103dde:	89 04 24             	mov    %eax,(%esp)
80103de1:	e8 78 ec ff ff       	call   80102a5e <kfree>
80103de6:	eb 0b                	jmp    80103df3 <pipeclose+0x90>
  } else
    release(&p->lock);
80103de8:	8b 45 08             	mov    0x8(%ebp),%eax
80103deb:	89 04 24             	mov    %eax,(%esp)
80103dee:	e8 32 0d 00 00       	call   80104b25 <release>
}
80103df3:	c9                   	leave  
80103df4:	c3                   	ret    

80103df5 <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
80103df5:	55                   	push   %ebp
80103df6:	89 e5                	mov    %esp,%ebp
80103df8:	53                   	push   %ebx
80103df9:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80103dfc:	8b 45 08             	mov    0x8(%ebp),%eax
80103dff:	89 04 24             	mov    %eax,(%esp)
80103e02:	e8 bc 0c 00 00       	call   80104ac3 <acquire>
  for(i = 0; i < n; i++){
80103e07:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103e0e:	e9 a6 00 00 00       	jmp    80103eb9 <pipewrite+0xc4>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
      if(p->readopen == 0 || proc->killed){
80103e13:	8b 45 08             	mov    0x8(%ebp),%eax
80103e16:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80103e1c:	85 c0                	test   %eax,%eax
80103e1e:	74 0d                	je     80103e2d <pipewrite+0x38>
80103e20:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80103e26:	8b 40 24             	mov    0x24(%eax),%eax
80103e29:	85 c0                	test   %eax,%eax
80103e2b:	74 15                	je     80103e42 <pipewrite+0x4d>
        release(&p->lock);
80103e2d:	8b 45 08             	mov    0x8(%ebp),%eax
80103e30:	89 04 24             	mov    %eax,(%esp)
80103e33:	e8 ed 0c 00 00       	call   80104b25 <release>
        return -1;
80103e38:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103e3d:	e9 9d 00 00 00       	jmp    80103edf <pipewrite+0xea>
      }
      wakeup(&p->nread);
80103e42:	8b 45 08             	mov    0x8(%ebp),%eax
80103e45:	05 34 02 00 00       	add    $0x234,%eax
80103e4a:	89 04 24             	mov    %eax,(%esp)
80103e4d:	e8 6e 0a 00 00       	call   801048c0 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
80103e52:	8b 45 08             	mov    0x8(%ebp),%eax
80103e55:	8b 55 08             	mov    0x8(%ebp),%edx
80103e58:	81 c2 38 02 00 00    	add    $0x238,%edx
80103e5e:	89 44 24 04          	mov    %eax,0x4(%esp)
80103e62:	89 14 24             	mov    %edx,(%esp)
80103e65:	e8 7d 09 00 00       	call   801047e7 <sleep>
80103e6a:	eb 01                	jmp    80103e6d <pipewrite+0x78>
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80103e6c:	90                   	nop
80103e6d:	8b 45 08             	mov    0x8(%ebp),%eax
80103e70:	8b 90 38 02 00 00    	mov    0x238(%eax),%edx
80103e76:	8b 45 08             	mov    0x8(%ebp),%eax
80103e79:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80103e7f:	05 00 02 00 00       	add    $0x200,%eax
80103e84:	39 c2                	cmp    %eax,%edx
80103e86:	74 8b                	je     80103e13 <pipewrite+0x1e>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
80103e88:	8b 45 08             	mov    0x8(%ebp),%eax
80103e8b:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80103e91:	89 c3                	mov    %eax,%ebx
80103e93:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
80103e99:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103e9c:	03 55 0c             	add    0xc(%ebp),%edx
80103e9f:	0f b6 0a             	movzbl (%edx),%ecx
80103ea2:	8b 55 08             	mov    0x8(%ebp),%edx
80103ea5:	88 4c 1a 34          	mov    %cl,0x34(%edx,%ebx,1)
80103ea9:	8d 50 01             	lea    0x1(%eax),%edx
80103eac:	8b 45 08             	mov    0x8(%ebp),%eax
80103eaf:	89 90 38 02 00 00    	mov    %edx,0x238(%eax)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
80103eb5:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103eb9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ebc:	3b 45 10             	cmp    0x10(%ebp),%eax
80103ebf:	7c ab                	jl     80103e6c <pipewrite+0x77>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
80103ec1:	8b 45 08             	mov    0x8(%ebp),%eax
80103ec4:	05 34 02 00 00       	add    $0x234,%eax
80103ec9:	89 04 24             	mov    %eax,(%esp)
80103ecc:	e8 ef 09 00 00       	call   801048c0 <wakeup>
  release(&p->lock);
80103ed1:	8b 45 08             	mov    0x8(%ebp),%eax
80103ed4:	89 04 24             	mov    %eax,(%esp)
80103ed7:	e8 49 0c 00 00       	call   80104b25 <release>
  return n;
80103edc:	8b 45 10             	mov    0x10(%ebp),%eax
}
80103edf:	83 c4 24             	add    $0x24,%esp
80103ee2:	5b                   	pop    %ebx
80103ee3:	5d                   	pop    %ebp
80103ee4:	c3                   	ret    

80103ee5 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
80103ee5:	55                   	push   %ebp
80103ee6:	89 e5                	mov    %esp,%ebp
80103ee8:	53                   	push   %ebx
80103ee9:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80103eec:	8b 45 08             	mov    0x8(%ebp),%eax
80103eef:	89 04 24             	mov    %eax,(%esp)
80103ef2:	e8 cc 0b 00 00       	call   80104ac3 <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80103ef7:	eb 3a                	jmp    80103f33 <piperead+0x4e>
    if(proc->killed){
80103ef9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80103eff:	8b 40 24             	mov    0x24(%eax),%eax
80103f02:	85 c0                	test   %eax,%eax
80103f04:	74 15                	je     80103f1b <piperead+0x36>
      release(&p->lock);
80103f06:	8b 45 08             	mov    0x8(%ebp),%eax
80103f09:	89 04 24             	mov    %eax,(%esp)
80103f0c:	e8 14 0c 00 00       	call   80104b25 <release>
      return -1;
80103f11:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103f16:	e9 b6 00 00 00       	jmp    80103fd1 <piperead+0xec>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
80103f1b:	8b 45 08             	mov    0x8(%ebp),%eax
80103f1e:	8b 55 08             	mov    0x8(%ebp),%edx
80103f21:	81 c2 34 02 00 00    	add    $0x234,%edx
80103f27:	89 44 24 04          	mov    %eax,0x4(%esp)
80103f2b:	89 14 24             	mov    %edx,(%esp)
80103f2e:	e8 b4 08 00 00       	call   801047e7 <sleep>
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80103f33:	8b 45 08             	mov    0x8(%ebp),%eax
80103f36:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80103f3c:	8b 45 08             	mov    0x8(%ebp),%eax
80103f3f:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80103f45:	39 c2                	cmp    %eax,%edx
80103f47:	75 0d                	jne    80103f56 <piperead+0x71>
80103f49:	8b 45 08             	mov    0x8(%ebp),%eax
80103f4c:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80103f52:	85 c0                	test   %eax,%eax
80103f54:	75 a3                	jne    80103ef9 <piperead+0x14>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80103f56:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103f5d:	eb 49                	jmp    80103fa8 <piperead+0xc3>
    if(p->nread == p->nwrite)
80103f5f:	8b 45 08             	mov    0x8(%ebp),%eax
80103f62:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80103f68:	8b 45 08             	mov    0x8(%ebp),%eax
80103f6b:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80103f71:	39 c2                	cmp    %eax,%edx
80103f73:	74 3d                	je     80103fb2 <piperead+0xcd>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
80103f75:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f78:	89 c2                	mov    %eax,%edx
80103f7a:	03 55 0c             	add    0xc(%ebp),%edx
80103f7d:	8b 45 08             	mov    0x8(%ebp),%eax
80103f80:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80103f86:	89 c3                	mov    %eax,%ebx
80103f88:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
80103f8e:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103f91:	0f b6 4c 19 34       	movzbl 0x34(%ecx,%ebx,1),%ecx
80103f96:	88 0a                	mov    %cl,(%edx)
80103f98:	8d 50 01             	lea    0x1(%eax),%edx
80103f9b:	8b 45 08             	mov    0x8(%ebp),%eax
80103f9e:	89 90 34 02 00 00    	mov    %edx,0x234(%eax)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80103fa4:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103fa8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103fab:	3b 45 10             	cmp    0x10(%ebp),%eax
80103fae:	7c af                	jl     80103f5f <piperead+0x7a>
80103fb0:	eb 01                	jmp    80103fb3 <piperead+0xce>
    if(p->nread == p->nwrite)
      break;
80103fb2:	90                   	nop
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
80103fb3:	8b 45 08             	mov    0x8(%ebp),%eax
80103fb6:	05 38 02 00 00       	add    $0x238,%eax
80103fbb:	89 04 24             	mov    %eax,(%esp)
80103fbe:	e8 fd 08 00 00       	call   801048c0 <wakeup>
  release(&p->lock);
80103fc3:	8b 45 08             	mov    0x8(%ebp),%eax
80103fc6:	89 04 24             	mov    %eax,(%esp)
80103fc9:	e8 57 0b 00 00       	call   80104b25 <release>
  return i;
80103fce:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80103fd1:	83 c4 24             	add    $0x24,%esp
80103fd4:	5b                   	pop    %ebx
80103fd5:	5d                   	pop    %ebp
80103fd6:	c3                   	ret    
	...

80103fd8 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80103fd8:	55                   	push   %ebp
80103fd9:	89 e5                	mov    %esp,%ebp
80103fdb:	53                   	push   %ebx
80103fdc:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103fdf:	9c                   	pushf  
80103fe0:	5b                   	pop    %ebx
80103fe1:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80103fe4:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103fe7:	83 c4 10             	add    $0x10,%esp
80103fea:	5b                   	pop    %ebx
80103feb:	5d                   	pop    %ebp
80103fec:	c3                   	ret    

80103fed <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
80103fed:	55                   	push   %ebp
80103fee:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80103ff0:	fb                   	sti    
}
80103ff1:	5d                   	pop    %ebp
80103ff2:	c3                   	ret    

80103ff3 <pinit>:

static void wakeup1(void *chan);

void
pinit(void)
{
80103ff3:	55                   	push   %ebp
80103ff4:	89 e5                	mov    %esp,%ebp
80103ff6:	83 ec 18             	sub    $0x18,%esp
  initlock(&ptable.lock, "ptable");
80103ff9:	c7 44 24 04 41 83 10 	movl   $0x80108341,0x4(%esp)
80104000:	80 
80104001:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104008:	e8 95 0a 00 00       	call   80104aa2 <initlock>
}
8010400d:	c9                   	leave  
8010400e:	c3                   	ret    

8010400f <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
8010400f:	55                   	push   %ebp
80104010:	89 e5                	mov    %esp,%ebp
80104012:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
80104015:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
8010401c:	e8 a2 0a 00 00       	call   80104ac3 <acquire>
  for(p = &ptable.proc[NPROC-1]; p >= 0; p--)
80104021:	c7 45 f4 d8 1d 11 80 	movl   $0x80111dd8,-0xc(%ebp)
    if(p->state == UNUSED)
80104028:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010402b:	8b 40 0c             	mov    0xc(%eax),%eax
8010402e:	85 c0                	test   %eax,%eax
80104030:	74 06                	je     80104038 <allocproc+0x29>
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = &ptable.proc[NPROC-1]; p >= 0; p--)
80104032:	83 6d f4 7c          	subl   $0x7c,-0xc(%ebp)
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
80104036:	eb f0                	jmp    80104028 <allocproc+0x19>
  char *sp;

  acquire(&ptable.lock);
  for(p = &ptable.proc[NPROC-1]; p >= 0; p--)
    if(p->state == UNUSED)
      goto found;
80104038:	90                   	nop
  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;
80104039:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010403c:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
  p->pid = nextpid++;
80104043:	a1 04 b0 10 80       	mov    0x8010b004,%eax
80104048:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010404b:	89 42 10             	mov    %eax,0x10(%edx)
8010404e:	83 c0 01             	add    $0x1,%eax
80104051:	a3 04 b0 10 80       	mov    %eax,0x8010b004
  release(&ptable.lock);
80104056:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
8010405d:	e8 c3 0a 00 00       	call   80104b25 <release>

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
80104062:	e8 90 ea ff ff       	call   80102af7 <kalloc>
80104067:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010406a:	89 42 08             	mov    %eax,0x8(%edx)
8010406d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104070:	8b 40 08             	mov    0x8(%eax),%eax
80104073:	85 c0                	test   %eax,%eax
80104075:	75 11                	jne    80104088 <allocproc+0x79>
    p->state = UNUSED;
80104077:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010407a:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return 0;
80104081:	b8 00 00 00 00       	mov    $0x0,%eax
80104086:	eb 65                	jmp    801040ed <allocproc+0xde>
  }
  sp = p->kstack + KSTACKSIZE;
80104088:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010408b:	8b 40 08             	mov    0x8(%eax),%eax
8010408e:	05 00 10 00 00       	add    $0x1000,%eax
80104093:	89 45 f0             	mov    %eax,-0x10(%ebp)
  
  // Leave room for trap frame.
  sp -= sizeof *p->tf;
80104096:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
  p->tf = (struct trapframe*)sp;
8010409a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010409d:	8b 55 f0             	mov    -0x10(%ebp),%edx
801040a0:	89 50 18             	mov    %edx,0x18(%eax)
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
801040a3:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
  *(uint*)sp = (uint)trapret;
801040a7:	ba 14 61 10 80       	mov    $0x80106114,%edx
801040ac:	8b 45 f0             	mov    -0x10(%ebp),%eax
801040af:	89 10                	mov    %edx,(%eax)

  sp -= sizeof *p->context;
801040b1:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
  p->context = (struct context*)sp;
801040b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801040b8:	8b 55 f0             	mov    -0x10(%ebp),%edx
801040bb:	89 50 1c             	mov    %edx,0x1c(%eax)
  memset(p->context, 0, sizeof *p->context);
801040be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801040c1:	8b 40 1c             	mov    0x1c(%eax),%eax
801040c4:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
801040cb:	00 
801040cc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801040d3:	00 
801040d4:	89 04 24             	mov    %eax,(%esp)
801040d7:	e8 36 0c 00 00       	call   80104d12 <memset>
  p->context->eip = (uint)forkret;
801040dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801040df:	8b 40 1c             	mov    0x1c(%eax),%eax
801040e2:	ba bb 47 10 80       	mov    $0x801047bb,%edx
801040e7:	89 50 10             	mov    %edx,0x10(%eax)

  return p;
801040ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801040ed:	c9                   	leave  
801040ee:	c3                   	ret    

801040ef <userinit>:

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
801040ef:	55                   	push   %ebp
801040f0:	89 e5                	mov    %esp,%ebp
801040f2:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
801040f5:	e8 15 ff ff ff       	call   8010400f <allocproc>
801040fa:	89 45 f4             	mov    %eax,-0xc(%ebp)
  initproc = p;
801040fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104100:	a3 48 b6 10 80       	mov    %eax,0x8010b648
  if((p->pgdir = setupkvm()) == 0)
80104105:	e8 07 37 00 00       	call   80107811 <setupkvm>
8010410a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010410d:	89 42 04             	mov    %eax,0x4(%edx)
80104110:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104113:	8b 40 04             	mov    0x4(%eax),%eax
80104116:	85 c0                	test   %eax,%eax
80104118:	75 0c                	jne    80104126 <userinit+0x37>
    panic("userinit: out of memory?");
8010411a:	c7 04 24 48 83 10 80 	movl   $0x80108348,(%esp)
80104121:	e8 17 c4 ff ff       	call   8010053d <panic>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80104126:	ba 2c 00 00 00       	mov    $0x2c,%edx
8010412b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010412e:	8b 40 04             	mov    0x4(%eax),%eax
80104131:	89 54 24 08          	mov    %edx,0x8(%esp)
80104135:	c7 44 24 04 e0 b4 10 	movl   $0x8010b4e0,0x4(%esp)
8010413c:	80 
8010413d:	89 04 24             	mov    %eax,(%esp)
80104140:	e8 24 39 00 00       	call   80107a69 <inituvm>
  p->sz = PGSIZE;
80104145:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104148:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  memset(p->tf, 0, sizeof(*p->tf));
8010414e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104151:	8b 40 18             	mov    0x18(%eax),%eax
80104154:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
8010415b:	00 
8010415c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104163:	00 
80104164:	89 04 24             	mov    %eax,(%esp)
80104167:	e8 a6 0b 00 00       	call   80104d12 <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
8010416c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010416f:	8b 40 18             	mov    0x18(%eax),%eax
80104172:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
80104178:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010417b:	8b 40 18             	mov    0x18(%eax),%eax
8010417e:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
  p->tf->es = p->tf->ds;
80104184:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104187:	8b 40 18             	mov    0x18(%eax),%eax
8010418a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010418d:	8b 52 18             	mov    0x18(%edx),%edx
80104190:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104194:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
80104198:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010419b:	8b 40 18             	mov    0x18(%eax),%eax
8010419e:	8b 55 f4             	mov    -0xc(%ebp),%edx
801041a1:	8b 52 18             	mov    0x18(%edx),%edx
801041a4:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
801041a8:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
801041ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041af:	8b 40 18             	mov    0x18(%eax),%eax
801041b2:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
801041b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041bc:	8b 40 18             	mov    0x18(%eax),%eax
801041bf:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
801041c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041c9:	8b 40 18             	mov    0x18(%eax),%eax
801041cc:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
801041d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041d6:	83 c0 6c             	add    $0x6c,%eax
801041d9:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
801041e0:	00 
801041e1:	c7 44 24 04 61 83 10 	movl   $0x80108361,0x4(%esp)
801041e8:	80 
801041e9:	89 04 24             	mov    %eax,(%esp)
801041ec:	e8 51 0d 00 00       	call   80104f42 <safestrcpy>
  p->cwd = namei("/");
801041f1:	c7 04 24 6a 83 10 80 	movl   $0x8010836a,(%esp)
801041f8:	e8 05 e2 ff ff       	call   80102402 <namei>
801041fd:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104200:	89 42 68             	mov    %eax,0x68(%edx)

  p->state = RUNNABLE;
80104203:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104206:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
}
8010420d:	c9                   	leave  
8010420e:	c3                   	ret    

8010420f <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
8010420f:	55                   	push   %ebp
80104210:	89 e5                	mov    %esp,%ebp
80104212:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  
  sz = proc->sz;
80104215:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010421b:	8b 00                	mov    (%eax),%eax
8010421d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
80104220:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80104224:	7e 34                	jle    8010425a <growproc+0x4b>
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
80104226:	8b 45 08             	mov    0x8(%ebp),%eax
80104229:	89 c2                	mov    %eax,%edx
8010422b:	03 55 f4             	add    -0xc(%ebp),%edx
8010422e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104234:	8b 40 04             	mov    0x4(%eax),%eax
80104237:	89 54 24 08          	mov    %edx,0x8(%esp)
8010423b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010423e:	89 54 24 04          	mov    %edx,0x4(%esp)
80104242:	89 04 24             	mov    %eax,(%esp)
80104245:	e8 99 39 00 00       	call   80107be3 <allocuvm>
8010424a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010424d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104251:	75 41                	jne    80104294 <growproc+0x85>
      return -1;
80104253:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104258:	eb 58                	jmp    801042b2 <growproc+0xa3>
  } else if(n < 0){
8010425a:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010425e:	79 34                	jns    80104294 <growproc+0x85>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
80104260:	8b 45 08             	mov    0x8(%ebp),%eax
80104263:	89 c2                	mov    %eax,%edx
80104265:	03 55 f4             	add    -0xc(%ebp),%edx
80104268:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010426e:	8b 40 04             	mov    0x4(%eax),%eax
80104271:	89 54 24 08          	mov    %edx,0x8(%esp)
80104275:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104278:	89 54 24 04          	mov    %edx,0x4(%esp)
8010427c:	89 04 24             	mov    %eax,(%esp)
8010427f:	e8 39 3a 00 00       	call   80107cbd <deallocuvm>
80104284:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104287:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010428b:	75 07                	jne    80104294 <growproc+0x85>
      return -1;
8010428d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104292:	eb 1e                	jmp    801042b2 <growproc+0xa3>
  }
  proc->sz = sz;
80104294:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010429a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010429d:	89 10                	mov    %edx,(%eax)
  switchuvm(proc);
8010429f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801042a5:	89 04 24             	mov    %eax,(%esp)
801042a8:	e8 55 36 00 00       	call   80107902 <switchuvm>
  return 0;
801042ad:	b8 00 00 00 00       	mov    $0x0,%eax
}
801042b2:	c9                   	leave  
801042b3:	c3                   	ret    

801042b4 <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
801042b4:	55                   	push   %ebp
801042b5:	89 e5                	mov    %esp,%ebp
801042b7:	57                   	push   %edi
801042b8:	56                   	push   %esi
801042b9:	53                   	push   %ebx
801042ba:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
801042bd:	e8 4d fd ff ff       	call   8010400f <allocproc>
801042c2:	89 45 e0             	mov    %eax,-0x20(%ebp)
801042c5:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
801042c9:	75 0a                	jne    801042d5 <fork+0x21>
    return -1;
801042cb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801042d0:	e9 3a 01 00 00       	jmp    8010440f <fork+0x15b>

  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
801042d5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801042db:	8b 10                	mov    (%eax),%edx
801042dd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801042e3:	8b 40 04             	mov    0x4(%eax),%eax
801042e6:	89 54 24 04          	mov    %edx,0x4(%esp)
801042ea:	89 04 24             	mov    %eax,(%esp)
801042ed:	e8 5b 3b 00 00       	call   80107e4d <copyuvm>
801042f2:	8b 55 e0             	mov    -0x20(%ebp),%edx
801042f5:	89 42 04             	mov    %eax,0x4(%edx)
801042f8:	8b 45 e0             	mov    -0x20(%ebp),%eax
801042fb:	8b 40 04             	mov    0x4(%eax),%eax
801042fe:	85 c0                	test   %eax,%eax
80104300:	75 2c                	jne    8010432e <fork+0x7a>
    kfree(np->kstack);
80104302:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104305:	8b 40 08             	mov    0x8(%eax),%eax
80104308:	89 04 24             	mov    %eax,(%esp)
8010430b:	e8 4e e7 ff ff       	call   80102a5e <kfree>
    np->kstack = 0;
80104310:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104313:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
8010431a:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010431d:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
80104324:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104329:	e9 e1 00 00 00       	jmp    8010440f <fork+0x15b>
  }
  np->sz = proc->sz;
8010432e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104334:	8b 10                	mov    (%eax),%edx
80104336:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104339:	89 10                	mov    %edx,(%eax)
  np->parent = proc;
8010433b:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104342:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104345:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *proc->tf;
80104348:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010434b:	8b 50 18             	mov    0x18(%eax),%edx
8010434e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104354:	8b 40 18             	mov    0x18(%eax),%eax
80104357:	89 c3                	mov    %eax,%ebx
80104359:	b8 13 00 00 00       	mov    $0x13,%eax
8010435e:	89 d7                	mov    %edx,%edi
80104360:	89 de                	mov    %ebx,%esi
80104362:	89 c1                	mov    %eax,%ecx
80104364:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
80104366:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104369:	8b 40 18             	mov    0x18(%eax),%eax
8010436c:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i <NOFILE; i++)
80104373:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
8010437a:	eb 3d                	jmp    801043b9 <fork+0x105>
    if(proc->ofile[i])
8010437c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104382:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104385:	83 c2 08             	add    $0x8,%edx
80104388:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010438c:	85 c0                	test   %eax,%eax
8010438e:	74 25                	je     801043b5 <fork+0x101>
      np->ofile[i] = filedup(proc->ofile[i]);
80104390:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104396:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104399:	83 c2 08             	add    $0x8,%edx
8010439c:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801043a0:	89 04 24             	mov    %eax,(%esp)
801043a3:	e8 cc cb ff ff       	call   80100f74 <filedup>
801043a8:	8b 55 e0             	mov    -0x20(%ebp),%edx
801043ab:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
801043ae:	83 c1 08             	add    $0x8,%ecx
801043b1:	89 44 8a 08          	mov    %eax,0x8(%edx,%ecx,4)
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i <NOFILE; i++)
801043b5:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
801043b9:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
801043bd:	7e bd                	jle    8010437c <fork+0xc8>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
801043bf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801043c5:	8b 40 68             	mov    0x68(%eax),%eax
801043c8:	89 04 24             	mov    %eax,(%esp)
801043cb:	e8 5e d4 ff ff       	call   8010182e <idup>
801043d0:	8b 55 e0             	mov    -0x20(%ebp),%edx
801043d3:	89 42 68             	mov    %eax,0x68(%edx)
 
  pid = np->pid;
801043d6:	8b 45 e0             	mov    -0x20(%ebp),%eax
801043d9:	8b 40 10             	mov    0x10(%eax),%eax
801043dc:	89 45 dc             	mov    %eax,-0x24(%ebp)
  np->state = RUNNABLE;
801043df:	8b 45 e0             	mov    -0x20(%ebp),%eax
801043e2:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  safestrcpy(np->name, proc->name, sizeof(proc->name));
801043e9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801043ef:	8d 50 6c             	lea    0x6c(%eax),%edx
801043f2:	8b 45 e0             	mov    -0x20(%ebp),%eax
801043f5:	83 c0 6c             	add    $0x6c,%eax
801043f8:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
801043ff:	00 
80104400:	89 54 24 04          	mov    %edx,0x4(%esp)
80104404:	89 04 24             	mov    %eax,(%esp)
80104407:	e8 36 0b 00 00       	call   80104f42 <safestrcpy>
  return pid;
8010440c:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
8010440f:	83 c4 2c             	add    $0x2c,%esp
80104412:	5b                   	pop    %ebx
80104413:	5e                   	pop    %esi
80104414:	5f                   	pop    %edi
80104415:	5d                   	pop    %ebp
80104416:	c3                   	ret    

80104417 <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
80104417:	55                   	push   %ebp
80104418:	89 e5                	mov    %esp,%ebp
8010441a:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int fd;

  if(proc == initproc)
8010441d:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104424:	a1 48 b6 10 80       	mov    0x8010b648,%eax
80104429:	39 c2                	cmp    %eax,%edx
8010442b:	75 0c                	jne    80104439 <exit+0x22>
    panic("init exiting");
8010442d:	c7 04 24 6c 83 10 80 	movl   $0x8010836c,(%esp)
80104434:	e8 04 c1 ff ff       	call   8010053d <panic>

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
80104439:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80104440:	eb 44                	jmp    80104486 <exit+0x6f>
    if(proc->ofile[fd]){
80104442:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104448:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010444b:	83 c2 08             	add    $0x8,%edx
8010444e:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104452:	85 c0                	test   %eax,%eax
80104454:	74 2c                	je     80104482 <exit+0x6b>
      fileclose(proc->ofile[fd]);
80104456:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010445c:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010445f:	83 c2 08             	add    $0x8,%edx
80104462:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104466:	89 04 24             	mov    %eax,(%esp)
80104469:	e8 4e cb ff ff       	call   80100fbc <fileclose>
      proc->ofile[fd] = 0;
8010446e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104474:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104477:	83 c2 08             	add    $0x8,%edx
8010447a:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80104481:	00 

  if(proc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
80104482:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80104486:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
8010448a:	7e b6                	jle    80104442 <exit+0x2b>
      fileclose(proc->ofile[fd]);
      proc->ofile[fd] = 0;
    }
  }

  iput(proc->cwd);
8010448c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104492:	8b 40 68             	mov    0x68(%eax),%eax
80104495:	89 04 24             	mov    %eax,(%esp)
80104498:	e8 76 d5 ff ff       	call   80101a13 <iput>
  proc->cwd = 0;
8010449d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801044a3:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)

  acquire(&ptable.lock);
801044aa:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
801044b1:	e8 0d 06 00 00       	call   80104ac3 <acquire>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);
801044b6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801044bc:	8b 40 14             	mov    0x14(%eax),%eax
801044bf:	89 04 24             	mov    %eax,(%esp)
801044c2:	e8 bb 03 00 00       	call   80104882 <wakeup1>

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801044c7:	c7 45 f4 54 ff 10 80 	movl   $0x8010ff54,-0xc(%ebp)
801044ce:	eb 38                	jmp    80104508 <exit+0xf1>
    if(p->parent == proc){
801044d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044d3:	8b 50 14             	mov    0x14(%eax),%edx
801044d6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801044dc:	39 c2                	cmp    %eax,%edx
801044de:	75 24                	jne    80104504 <exit+0xed>
      p->parent = initproc;
801044e0:	8b 15 48 b6 10 80    	mov    0x8010b648,%edx
801044e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044e9:	89 50 14             	mov    %edx,0x14(%eax)
      if(p->state == ZOMBIE)
801044ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044ef:	8b 40 0c             	mov    0xc(%eax),%eax
801044f2:	83 f8 05             	cmp    $0x5,%eax
801044f5:	75 0d                	jne    80104504 <exit+0xed>
        wakeup1(initproc);
801044f7:	a1 48 b6 10 80       	mov    0x8010b648,%eax
801044fc:	89 04 24             	mov    %eax,(%esp)
801044ff:	e8 7e 03 00 00       	call   80104882 <wakeup1>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104504:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104508:	81 7d f4 54 1e 11 80 	cmpl   $0x80111e54,-0xc(%ebp)
8010450f:	72 bf                	jb     801044d0 <exit+0xb9>
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  proc->state = ZOMBIE;
80104511:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104517:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
  sched();
8010451e:	e8 b4 01 00 00       	call   801046d7 <sched>
  panic("zombie exit");
80104523:	c7 04 24 79 83 10 80 	movl   $0x80108379,(%esp)
8010452a:	e8 0e c0 ff ff       	call   8010053d <panic>

8010452f <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
8010452f:	55                   	push   %ebp
80104530:	89 e5                	mov    %esp,%ebp
80104532:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
80104535:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
8010453c:	e8 82 05 00 00       	call   80104ac3 <acquire>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
80104541:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104548:	c7 45 f4 54 ff 10 80 	movl   $0x8010ff54,-0xc(%ebp)
8010454f:	e9 9a 00 00 00       	jmp    801045ee <wait+0xbf>
      if(p->parent != proc)
80104554:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104557:	8b 50 14             	mov    0x14(%eax),%edx
8010455a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104560:	39 c2                	cmp    %eax,%edx
80104562:	0f 85 81 00 00 00    	jne    801045e9 <wait+0xba>
        continue;
      havekids = 1;
80104568:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
      if(p->state == ZOMBIE){
8010456f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104572:	8b 40 0c             	mov    0xc(%eax),%eax
80104575:	83 f8 05             	cmp    $0x5,%eax
80104578:	75 70                	jne    801045ea <wait+0xbb>
        // Found one.
        pid = p->pid;
8010457a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010457d:	8b 40 10             	mov    0x10(%eax),%eax
80104580:	89 45 ec             	mov    %eax,-0x14(%ebp)
        kfree(p->kstack);
80104583:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104586:	8b 40 08             	mov    0x8(%eax),%eax
80104589:	89 04 24             	mov    %eax,(%esp)
8010458c:	e8 cd e4 ff ff       	call   80102a5e <kfree>
        p->kstack = 0;
80104591:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104594:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
        freevm(p->pgdir);
8010459b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010459e:	8b 40 04             	mov    0x4(%eax),%eax
801045a1:	89 04 24             	mov    %eax,(%esp)
801045a4:	e8 d0 37 00 00       	call   80107d79 <freevm>
        p->state = UNUSED;
801045a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045ac:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
        p->pid = 0;
801045b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045b6:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
        p->parent = 0;
801045bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045c0:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
        p->name[0] = 0;
801045c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045ca:	c6 40 6c 00          	movb   $0x0,0x6c(%eax)
        p->killed = 0;
801045ce:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045d1:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
        release(&ptable.lock);
801045d8:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
801045df:	e8 41 05 00 00       	call   80104b25 <release>
        return pid;
801045e4:	8b 45 ec             	mov    -0x14(%ebp),%eax
801045e7:	eb 53                	jmp    8010463c <wait+0x10d>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->parent != proc)
        continue;
801045e9:	90                   	nop

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801045ea:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
801045ee:	81 7d f4 54 1e 11 80 	cmpl   $0x80111e54,-0xc(%ebp)
801045f5:	0f 82 59 ff ff ff    	jb     80104554 <wait+0x25>
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
801045fb:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801045ff:	74 0d                	je     8010460e <wait+0xdf>
80104601:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104607:	8b 40 24             	mov    0x24(%eax),%eax
8010460a:	85 c0                	test   %eax,%eax
8010460c:	74 13                	je     80104621 <wait+0xf2>
      release(&ptable.lock);
8010460e:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104615:	e8 0b 05 00 00       	call   80104b25 <release>
      return -1;
8010461a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010461f:	eb 1b                	jmp    8010463c <wait+0x10d>
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
80104621:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104627:	c7 44 24 04 20 ff 10 	movl   $0x8010ff20,0x4(%esp)
8010462e:	80 
8010462f:	89 04 24             	mov    %eax,(%esp)
80104632:	e8 b0 01 00 00       	call   801047e7 <sleep>
  }
80104637:	e9 05 ff ff ff       	jmp    80104541 <wait+0x12>
}
8010463c:	c9                   	leave  
8010463d:	c3                   	ret    

8010463e <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
8010463e:	55                   	push   %ebp
8010463f:	89 e5                	mov    %esp,%ebp
80104641:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  for(;;){
    // Enable interrupts on this processor.
    sti();
80104644:	e8 a4 f9 ff ff       	call   80103fed <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
80104649:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104650:	e8 6e 04 00 00       	call   80104ac3 <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104655:	c7 45 f4 54 ff 10 80 	movl   $0x8010ff54,-0xc(%ebp)
8010465c:	eb 5f                	jmp    801046bd <scheduler+0x7f>
      if(p->state != RUNNABLE)
8010465e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104661:	8b 40 0c             	mov    0xc(%eax),%eax
80104664:	83 f8 03             	cmp    $0x3,%eax
80104667:	75 4f                	jne    801046b8 <scheduler+0x7a>
        continue;

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
80104669:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010466c:	65 a3 04 00 00 00    	mov    %eax,%gs:0x4
      switchuvm(p);
80104672:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104675:	89 04 24             	mov    %eax,(%esp)
80104678:	e8 85 32 00 00       	call   80107902 <switchuvm>
      p->state = RUNNING;
8010467d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104680:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
      swtch(&cpu->scheduler, proc->context);
80104687:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010468d:	8b 40 1c             	mov    0x1c(%eax),%eax
80104690:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80104697:	83 c2 04             	add    $0x4,%edx
8010469a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010469e:	89 14 24             	mov    %edx,(%esp)
801046a1:	e8 12 09 00 00       	call   80104fb8 <swtch>
      switchkvm();
801046a6:	e8 3a 32 00 00       	call   801078e5 <switchkvm>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
801046ab:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
801046b2:	00 00 00 00 
801046b6:	eb 01                	jmp    801046b9 <scheduler+0x7b>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->state != RUNNABLE)
        continue;
801046b8:	90                   	nop
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801046b9:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
801046bd:	81 7d f4 54 1e 11 80 	cmpl   $0x80111e54,-0xc(%ebp)
801046c4:	72 98                	jb     8010465e <scheduler+0x20>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);
801046c6:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
801046cd:	e8 53 04 00 00       	call   80104b25 <release>

  }
801046d2:	e9 6d ff ff ff       	jmp    80104644 <scheduler+0x6>

801046d7 <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
801046d7:	55                   	push   %ebp
801046d8:	89 e5                	mov    %esp,%ebp
801046da:	83 ec 28             	sub    $0x28,%esp
  int intena;

  if(!holding(&ptable.lock))
801046dd:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
801046e4:	e8 f8 04 00 00       	call   80104be1 <holding>
801046e9:	85 c0                	test   %eax,%eax
801046eb:	75 0c                	jne    801046f9 <sched+0x22>
    panic("sched ptable.lock");
801046ed:	c7 04 24 85 83 10 80 	movl   $0x80108385,(%esp)
801046f4:	e8 44 be ff ff       	call   8010053d <panic>
  if(cpu->ncli != 1)
801046f9:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801046ff:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80104705:	83 f8 01             	cmp    $0x1,%eax
80104708:	74 0c                	je     80104716 <sched+0x3f>
    panic("sched locks");
8010470a:	c7 04 24 97 83 10 80 	movl   $0x80108397,(%esp)
80104711:	e8 27 be ff ff       	call   8010053d <panic>
  if(proc->state == RUNNING)
80104716:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010471c:	8b 40 0c             	mov    0xc(%eax),%eax
8010471f:	83 f8 04             	cmp    $0x4,%eax
80104722:	75 0c                	jne    80104730 <sched+0x59>
    panic("sched running");
80104724:	c7 04 24 a3 83 10 80 	movl   $0x801083a3,(%esp)
8010472b:	e8 0d be ff ff       	call   8010053d <panic>
  if(readeflags()&FL_IF)
80104730:	e8 a3 f8 ff ff       	call   80103fd8 <readeflags>
80104735:	25 00 02 00 00       	and    $0x200,%eax
8010473a:	85 c0                	test   %eax,%eax
8010473c:	74 0c                	je     8010474a <sched+0x73>
    panic("sched interruptible");
8010473e:	c7 04 24 b1 83 10 80 	movl   $0x801083b1,(%esp)
80104745:	e8 f3 bd ff ff       	call   8010053d <panic>
  intena = cpu->intena;
8010474a:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104750:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80104756:	89 45 f4             	mov    %eax,-0xc(%ebp)
  swtch(&proc->context, cpu->scheduler);
80104759:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010475f:	8b 40 04             	mov    0x4(%eax),%eax
80104762:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104769:	83 c2 1c             	add    $0x1c,%edx
8010476c:	89 44 24 04          	mov    %eax,0x4(%esp)
80104770:	89 14 24             	mov    %edx,(%esp)
80104773:	e8 40 08 00 00       	call   80104fb8 <swtch>
  cpu->intena = intena;
80104778:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010477e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104781:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80104787:	c9                   	leave  
80104788:	c3                   	ret    

80104789 <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
80104789:	55                   	push   %ebp
8010478a:	89 e5                	mov    %esp,%ebp
8010478c:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
8010478f:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104796:	e8 28 03 00 00       	call   80104ac3 <acquire>
  proc->state = RUNNABLE;
8010479b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047a1:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
801047a8:	e8 2a ff ff ff       	call   801046d7 <sched>
  release(&ptable.lock);
801047ad:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
801047b4:	e8 6c 03 00 00       	call   80104b25 <release>
}
801047b9:	c9                   	leave  
801047ba:	c3                   	ret    

801047bb <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
801047bb:	55                   	push   %ebp
801047bc:	89 e5                	mov    %esp,%ebp
801047be:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
801047c1:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
801047c8:	e8 58 03 00 00       	call   80104b25 <release>

  if (first) {
801047cd:	a1 20 b0 10 80       	mov    0x8010b020,%eax
801047d2:	85 c0                	test   %eax,%eax
801047d4:	74 0f                	je     801047e5 <forkret+0x2a>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
801047d6:	c7 05 20 b0 10 80 00 	movl   $0x0,0x8010b020
801047dd:	00 00 00 
    initlog();
801047e0:	e8 23 e8 ff ff       	call   80103008 <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
801047e5:	c9                   	leave  
801047e6:	c3                   	ret    

801047e7 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
801047e7:	55                   	push   %ebp
801047e8:	89 e5                	mov    %esp,%ebp
801047ea:	83 ec 18             	sub    $0x18,%esp
  if(proc == 0)
801047ed:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047f3:	85 c0                	test   %eax,%eax
801047f5:	75 0c                	jne    80104803 <sleep+0x1c>
    panic("sleep");
801047f7:	c7 04 24 c5 83 10 80 	movl   $0x801083c5,(%esp)
801047fe:	e8 3a bd ff ff       	call   8010053d <panic>

  if(lk == 0)
80104803:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80104807:	75 0c                	jne    80104815 <sleep+0x2e>
    panic("sleep without lk");
80104809:	c7 04 24 cb 83 10 80 	movl   $0x801083cb,(%esp)
80104810:	e8 28 bd ff ff       	call   8010053d <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
80104815:	81 7d 0c 20 ff 10 80 	cmpl   $0x8010ff20,0xc(%ebp)
8010481c:	74 17                	je     80104835 <sleep+0x4e>
    acquire(&ptable.lock);  //DOC: sleeplock1
8010481e:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104825:	e8 99 02 00 00       	call   80104ac3 <acquire>
    release(lk);
8010482a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010482d:	89 04 24             	mov    %eax,(%esp)
80104830:	e8 f0 02 00 00       	call   80104b25 <release>
  }

  // Go to sleep.
  proc->chan = chan;
80104835:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010483b:	8b 55 08             	mov    0x8(%ebp),%edx
8010483e:	89 50 20             	mov    %edx,0x20(%eax)
  proc->state = SLEEPING;
80104841:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104847:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
  sched();
8010484e:	e8 84 fe ff ff       	call   801046d7 <sched>

  // Tidy up.
  proc->chan = 0;
80104853:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104859:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
80104860:	81 7d 0c 20 ff 10 80 	cmpl   $0x8010ff20,0xc(%ebp)
80104867:	74 17                	je     80104880 <sleep+0x99>
    release(&ptable.lock);
80104869:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104870:	e8 b0 02 00 00       	call   80104b25 <release>
    acquire(lk);
80104875:	8b 45 0c             	mov    0xc(%ebp),%eax
80104878:	89 04 24             	mov    %eax,(%esp)
8010487b:	e8 43 02 00 00       	call   80104ac3 <acquire>
  }
}
80104880:	c9                   	leave  
80104881:	c3                   	ret    

80104882 <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80104882:	55                   	push   %ebp
80104883:	89 e5                	mov    %esp,%ebp
80104885:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104888:	c7 45 fc 54 ff 10 80 	movl   $0x8010ff54,-0x4(%ebp)
8010488f:	eb 24                	jmp    801048b5 <wakeup1+0x33>
    if(p->state == SLEEPING && p->chan == chan)
80104891:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104894:	8b 40 0c             	mov    0xc(%eax),%eax
80104897:	83 f8 02             	cmp    $0x2,%eax
8010489a:	75 15                	jne    801048b1 <wakeup1+0x2f>
8010489c:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010489f:	8b 40 20             	mov    0x20(%eax),%eax
801048a2:	3b 45 08             	cmp    0x8(%ebp),%eax
801048a5:	75 0a                	jne    801048b1 <wakeup1+0x2f>
      p->state = RUNNABLE;
801048a7:	8b 45 fc             	mov    -0x4(%ebp),%eax
801048aa:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801048b1:	83 45 fc 7c          	addl   $0x7c,-0x4(%ebp)
801048b5:	81 7d fc 54 1e 11 80 	cmpl   $0x80111e54,-0x4(%ebp)
801048bc:	72 d3                	jb     80104891 <wakeup1+0xf>
    if(p->state == SLEEPING && p->chan == chan)
      p->state = RUNNABLE;
}
801048be:	c9                   	leave  
801048bf:	c3                   	ret    

801048c0 <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
801048c0:	55                   	push   %ebp
801048c1:	89 e5                	mov    %esp,%ebp
801048c3:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);
801048c6:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
801048cd:	e8 f1 01 00 00       	call   80104ac3 <acquire>
  wakeup1(chan);
801048d2:	8b 45 08             	mov    0x8(%ebp),%eax
801048d5:	89 04 24             	mov    %eax,(%esp)
801048d8:	e8 a5 ff ff ff       	call   80104882 <wakeup1>
  release(&ptable.lock);
801048dd:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
801048e4:	e8 3c 02 00 00       	call   80104b25 <release>
}
801048e9:	c9                   	leave  
801048ea:	c3                   	ret    

801048eb <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
801048eb:	55                   	push   %ebp
801048ec:	89 e5                	mov    %esp,%ebp
801048ee:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  acquire(&ptable.lock);
801048f1:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
801048f8:	e8 c6 01 00 00       	call   80104ac3 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801048fd:	c7 45 f4 54 ff 10 80 	movl   $0x8010ff54,-0xc(%ebp)
80104904:	eb 41                	jmp    80104947 <kill+0x5c>
    if(p->pid == pid){
80104906:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104909:	8b 40 10             	mov    0x10(%eax),%eax
8010490c:	3b 45 08             	cmp    0x8(%ebp),%eax
8010490f:	75 32                	jne    80104943 <kill+0x58>
      p->killed = 1;
80104911:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104914:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
8010491b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010491e:	8b 40 0c             	mov    0xc(%eax),%eax
80104921:	83 f8 02             	cmp    $0x2,%eax
80104924:	75 0a                	jne    80104930 <kill+0x45>
        p->state = RUNNABLE;
80104926:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104929:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      release(&ptable.lock);
80104930:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104937:	e8 e9 01 00 00       	call   80104b25 <release>
      return 0;
8010493c:	b8 00 00 00 00       	mov    $0x0,%eax
80104941:	eb 1e                	jmp    80104961 <kill+0x76>
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104943:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104947:	81 7d f4 54 1e 11 80 	cmpl   $0x80111e54,-0xc(%ebp)
8010494e:	72 b6                	jb     80104906 <kill+0x1b>
        p->state = RUNNABLE;
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
80104950:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104957:	e8 c9 01 00 00       	call   80104b25 <release>
  return -1;
8010495c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104961:	c9                   	leave  
80104962:	c3                   	ret    

80104963 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
80104963:	55                   	push   %ebp
80104964:	89 e5                	mov    %esp,%ebp
80104966:	83 ec 58             	sub    $0x58,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104969:	c7 45 f0 54 ff 10 80 	movl   $0x8010ff54,-0x10(%ebp)
80104970:	e9 d8 00 00 00       	jmp    80104a4d <procdump+0xea>
    if(p->state == UNUSED)
80104975:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104978:	8b 40 0c             	mov    0xc(%eax),%eax
8010497b:	85 c0                	test   %eax,%eax
8010497d:	0f 84 c5 00 00 00    	je     80104a48 <procdump+0xe5>
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80104983:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104986:	8b 40 0c             	mov    0xc(%eax),%eax
80104989:	83 f8 05             	cmp    $0x5,%eax
8010498c:	77 23                	ja     801049b1 <procdump+0x4e>
8010498e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104991:	8b 40 0c             	mov    0xc(%eax),%eax
80104994:	8b 04 85 08 b0 10 80 	mov    -0x7fef4ff8(,%eax,4),%eax
8010499b:	85 c0                	test   %eax,%eax
8010499d:	74 12                	je     801049b1 <procdump+0x4e>
      state = states[p->state];
8010499f:	8b 45 f0             	mov    -0x10(%ebp),%eax
801049a2:	8b 40 0c             	mov    0xc(%eax),%eax
801049a5:	8b 04 85 08 b0 10 80 	mov    -0x7fef4ff8(,%eax,4),%eax
801049ac:	89 45 ec             	mov    %eax,-0x14(%ebp)
801049af:	eb 07                	jmp    801049b8 <procdump+0x55>
    else
      state = "???";
801049b1:	c7 45 ec dc 83 10 80 	movl   $0x801083dc,-0x14(%ebp)
    cprintf("%d %s %s", p->pid, state, p->name);
801049b8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801049bb:	8d 50 6c             	lea    0x6c(%eax),%edx
801049be:	8b 45 f0             	mov    -0x10(%ebp),%eax
801049c1:	8b 40 10             	mov    0x10(%eax),%eax
801049c4:	89 54 24 0c          	mov    %edx,0xc(%esp)
801049c8:	8b 55 ec             	mov    -0x14(%ebp),%edx
801049cb:	89 54 24 08          	mov    %edx,0x8(%esp)
801049cf:	89 44 24 04          	mov    %eax,0x4(%esp)
801049d3:	c7 04 24 e0 83 10 80 	movl   $0x801083e0,(%esp)
801049da:	e8 c2 b9 ff ff       	call   801003a1 <cprintf>
    if(p->state == SLEEPING){
801049df:	8b 45 f0             	mov    -0x10(%ebp),%eax
801049e2:	8b 40 0c             	mov    0xc(%eax),%eax
801049e5:	83 f8 02             	cmp    $0x2,%eax
801049e8:	75 50                	jne    80104a3a <procdump+0xd7>
      getcallerpcs((uint*)p->context->ebp+2, pc);
801049ea:	8b 45 f0             	mov    -0x10(%ebp),%eax
801049ed:	8b 40 1c             	mov    0x1c(%eax),%eax
801049f0:	8b 40 0c             	mov    0xc(%eax),%eax
801049f3:	83 c0 08             	add    $0x8,%eax
801049f6:	8d 55 c4             	lea    -0x3c(%ebp),%edx
801049f9:	89 54 24 04          	mov    %edx,0x4(%esp)
801049fd:	89 04 24             	mov    %eax,(%esp)
80104a00:	e8 6f 01 00 00       	call   80104b74 <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80104a05:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104a0c:	eb 1b                	jmp    80104a29 <procdump+0xc6>
        cprintf(" %p", pc[i]);
80104a0e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a11:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80104a15:	89 44 24 04          	mov    %eax,0x4(%esp)
80104a19:	c7 04 24 e9 83 10 80 	movl   $0x801083e9,(%esp)
80104a20:	e8 7c b9 ff ff       	call   801003a1 <cprintf>
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
80104a25:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104a29:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
80104a2d:	7f 0b                	jg     80104a3a <procdump+0xd7>
80104a2f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a32:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80104a36:	85 c0                	test   %eax,%eax
80104a38:	75 d4                	jne    80104a0e <procdump+0xab>
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80104a3a:	c7 04 24 ed 83 10 80 	movl   $0x801083ed,(%esp)
80104a41:	e8 5b b9 ff ff       	call   801003a1 <cprintf>
80104a46:	eb 01                	jmp    80104a49 <procdump+0xe6>
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
80104a48:	90                   	nop
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104a49:	83 45 f0 7c          	addl   $0x7c,-0x10(%ebp)
80104a4d:	81 7d f0 54 1e 11 80 	cmpl   $0x80111e54,-0x10(%ebp)
80104a54:	0f 82 1b ff ff ff    	jb     80104975 <procdump+0x12>
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
}
80104a5a:	c9                   	leave  
80104a5b:	c3                   	ret    

80104a5c <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80104a5c:	55                   	push   %ebp
80104a5d:	89 e5                	mov    %esp,%ebp
80104a5f:	53                   	push   %ebx
80104a60:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80104a63:	9c                   	pushf  
80104a64:	5b                   	pop    %ebx
80104a65:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80104a68:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80104a6b:	83 c4 10             	add    $0x10,%esp
80104a6e:	5b                   	pop    %ebx
80104a6f:	5d                   	pop    %ebp
80104a70:	c3                   	ret    

80104a71 <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
80104a71:	55                   	push   %ebp
80104a72:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
80104a74:	fa                   	cli    
}
80104a75:	5d                   	pop    %ebp
80104a76:	c3                   	ret    

80104a77 <sti>:

static inline void
sti(void)
{
80104a77:	55                   	push   %ebp
80104a78:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80104a7a:	fb                   	sti    
}
80104a7b:	5d                   	pop    %ebp
80104a7c:	c3                   	ret    

80104a7d <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
80104a7d:	55                   	push   %ebp
80104a7e:	89 e5                	mov    %esp,%ebp
80104a80:	53                   	push   %ebx
80104a81:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
80104a84:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80104a87:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
80104a8a:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80104a8d:	89 c3                	mov    %eax,%ebx
80104a8f:	89 d8                	mov    %ebx,%eax
80104a91:	f0 87 02             	lock xchg %eax,(%edx)
80104a94:	89 c3                	mov    %eax,%ebx
80104a96:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80104a99:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80104a9c:	83 c4 10             	add    $0x10,%esp
80104a9f:	5b                   	pop    %ebx
80104aa0:	5d                   	pop    %ebp
80104aa1:	c3                   	ret    

80104aa2 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80104aa2:	55                   	push   %ebp
80104aa3:	89 e5                	mov    %esp,%ebp
  lk->name = name;
80104aa5:	8b 45 08             	mov    0x8(%ebp),%eax
80104aa8:	8b 55 0c             	mov    0xc(%ebp),%edx
80104aab:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80104aae:	8b 45 08             	mov    0x8(%ebp),%eax
80104ab1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80104ab7:	8b 45 08             	mov    0x8(%ebp),%eax
80104aba:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80104ac1:	5d                   	pop    %ebp
80104ac2:	c3                   	ret    

80104ac3 <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
80104ac3:	55                   	push   %ebp
80104ac4:	89 e5                	mov    %esp,%ebp
80104ac6:	83 ec 18             	sub    $0x18,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80104ac9:	e8 3d 01 00 00       	call   80104c0b <pushcli>
  if(holding(lk))
80104ace:	8b 45 08             	mov    0x8(%ebp),%eax
80104ad1:	89 04 24             	mov    %eax,(%esp)
80104ad4:	e8 08 01 00 00       	call   80104be1 <holding>
80104ad9:	85 c0                	test   %eax,%eax
80104adb:	74 0c                	je     80104ae9 <acquire+0x26>
    panic("acquire");
80104add:	c7 04 24 19 84 10 80 	movl   $0x80108419,(%esp)
80104ae4:	e8 54 ba ff ff       	call   8010053d <panic>

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
80104ae9:	90                   	nop
80104aea:	8b 45 08             	mov    0x8(%ebp),%eax
80104aed:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80104af4:	00 
80104af5:	89 04 24             	mov    %eax,(%esp)
80104af8:	e8 80 ff ff ff       	call   80104a7d <xchg>
80104afd:	85 c0                	test   %eax,%eax
80104aff:	75 e9                	jne    80104aea <acquire+0x27>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
80104b01:	8b 45 08             	mov    0x8(%ebp),%eax
80104b04:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80104b0b:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
80104b0e:	8b 45 08             	mov    0x8(%ebp),%eax
80104b11:	83 c0 0c             	add    $0xc,%eax
80104b14:	89 44 24 04          	mov    %eax,0x4(%esp)
80104b18:	8d 45 08             	lea    0x8(%ebp),%eax
80104b1b:	89 04 24             	mov    %eax,(%esp)
80104b1e:	e8 51 00 00 00       	call   80104b74 <getcallerpcs>
}
80104b23:	c9                   	leave  
80104b24:	c3                   	ret    

80104b25 <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
80104b25:	55                   	push   %ebp
80104b26:	89 e5                	mov    %esp,%ebp
80104b28:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
80104b2b:	8b 45 08             	mov    0x8(%ebp),%eax
80104b2e:	89 04 24             	mov    %eax,(%esp)
80104b31:	e8 ab 00 00 00       	call   80104be1 <holding>
80104b36:	85 c0                	test   %eax,%eax
80104b38:	75 0c                	jne    80104b46 <release+0x21>
    panic("release");
80104b3a:	c7 04 24 21 84 10 80 	movl   $0x80108421,(%esp)
80104b41:	e8 f7 b9 ff ff       	call   8010053d <panic>

  lk->pcs[0] = 0;
80104b46:	8b 45 08             	mov    0x8(%ebp),%eax
80104b49:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
80104b50:	8b 45 08             	mov    0x8(%ebp),%eax
80104b53:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
80104b5a:	8b 45 08             	mov    0x8(%ebp),%eax
80104b5d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104b64:	00 
80104b65:	89 04 24             	mov    %eax,(%esp)
80104b68:	e8 10 ff ff ff       	call   80104a7d <xchg>

  popcli();
80104b6d:	e8 e1 00 00 00       	call   80104c53 <popcli>
}
80104b72:	c9                   	leave  
80104b73:	c3                   	ret    

80104b74 <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80104b74:	55                   	push   %ebp
80104b75:	89 e5                	mov    %esp,%ebp
80104b77:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
80104b7a:	8b 45 08             	mov    0x8(%ebp),%eax
80104b7d:	83 e8 08             	sub    $0x8,%eax
80104b80:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
80104b83:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
80104b8a:	eb 32                	jmp    80104bbe <getcallerpcs+0x4a>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80104b8c:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
80104b90:	74 47                	je     80104bd9 <getcallerpcs+0x65>
80104b92:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
80104b99:	76 3e                	jbe    80104bd9 <getcallerpcs+0x65>
80104b9b:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
80104b9f:	74 38                	je     80104bd9 <getcallerpcs+0x65>
      break;
    pcs[i] = ebp[1];     // saved %eip
80104ba1:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104ba4:	c1 e0 02             	shl    $0x2,%eax
80104ba7:	03 45 0c             	add    0xc(%ebp),%eax
80104baa:	8b 55 fc             	mov    -0x4(%ebp),%edx
80104bad:	8b 52 04             	mov    0x4(%edx),%edx
80104bb0:	89 10                	mov    %edx,(%eax)
    ebp = (uint*)ebp[0]; // saved %ebp
80104bb2:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104bb5:	8b 00                	mov    (%eax),%eax
80104bb7:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
80104bba:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80104bbe:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80104bc2:	7e c8                	jle    80104b8c <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80104bc4:	eb 13                	jmp    80104bd9 <getcallerpcs+0x65>
    pcs[i] = 0;
80104bc6:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104bc9:	c1 e0 02             	shl    $0x2,%eax
80104bcc:	03 45 0c             	add    0xc(%ebp),%eax
80104bcf:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80104bd5:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80104bd9:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80104bdd:	7e e7                	jle    80104bc6 <getcallerpcs+0x52>
    pcs[i] = 0;
}
80104bdf:	c9                   	leave  
80104be0:	c3                   	ret    

80104be1 <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
80104be1:	55                   	push   %ebp
80104be2:	89 e5                	mov    %esp,%ebp
  return lock->locked && lock->cpu == cpu;
80104be4:	8b 45 08             	mov    0x8(%ebp),%eax
80104be7:	8b 00                	mov    (%eax),%eax
80104be9:	85 c0                	test   %eax,%eax
80104beb:	74 17                	je     80104c04 <holding+0x23>
80104bed:	8b 45 08             	mov    0x8(%ebp),%eax
80104bf0:	8b 50 08             	mov    0x8(%eax),%edx
80104bf3:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104bf9:	39 c2                	cmp    %eax,%edx
80104bfb:	75 07                	jne    80104c04 <holding+0x23>
80104bfd:	b8 01 00 00 00       	mov    $0x1,%eax
80104c02:	eb 05                	jmp    80104c09 <holding+0x28>
80104c04:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104c09:	5d                   	pop    %ebp
80104c0a:	c3                   	ret    

80104c0b <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80104c0b:	55                   	push   %ebp
80104c0c:	89 e5                	mov    %esp,%ebp
80104c0e:	83 ec 10             	sub    $0x10,%esp
  int eflags;
  
  eflags = readeflags();
80104c11:	e8 46 fe ff ff       	call   80104a5c <readeflags>
80104c16:	89 45 fc             	mov    %eax,-0x4(%ebp)
  cli();
80104c19:	e8 53 fe ff ff       	call   80104a71 <cli>
  if(cpu->ncli++ == 0)
80104c1e:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104c24:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80104c2a:	85 d2                	test   %edx,%edx
80104c2c:	0f 94 c1             	sete   %cl
80104c2f:	83 c2 01             	add    $0x1,%edx
80104c32:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80104c38:	84 c9                	test   %cl,%cl
80104c3a:	74 15                	je     80104c51 <pushcli+0x46>
    cpu->intena = eflags & FL_IF;
80104c3c:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104c42:	8b 55 fc             	mov    -0x4(%ebp),%edx
80104c45:	81 e2 00 02 00 00    	and    $0x200,%edx
80104c4b:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80104c51:	c9                   	leave  
80104c52:	c3                   	ret    

80104c53 <popcli>:

void
popcli(void)
{
80104c53:	55                   	push   %ebp
80104c54:	89 e5                	mov    %esp,%ebp
80104c56:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
80104c59:	e8 fe fd ff ff       	call   80104a5c <readeflags>
80104c5e:	25 00 02 00 00       	and    $0x200,%eax
80104c63:	85 c0                	test   %eax,%eax
80104c65:	74 0c                	je     80104c73 <popcli+0x20>
    panic("popcli - interruptible");
80104c67:	c7 04 24 29 84 10 80 	movl   $0x80108429,(%esp)
80104c6e:	e8 ca b8 ff ff       	call   8010053d <panic>
  if(--cpu->ncli < 0)
80104c73:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104c79:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80104c7f:	83 ea 01             	sub    $0x1,%edx
80104c82:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80104c88:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80104c8e:	85 c0                	test   %eax,%eax
80104c90:	79 0c                	jns    80104c9e <popcli+0x4b>
    panic("popcli");
80104c92:	c7 04 24 40 84 10 80 	movl   $0x80108440,(%esp)
80104c99:	e8 9f b8 ff ff       	call   8010053d <panic>
  if(cpu->ncli == 0 && cpu->intena)
80104c9e:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104ca4:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80104caa:	85 c0                	test   %eax,%eax
80104cac:	75 15                	jne    80104cc3 <popcli+0x70>
80104cae:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104cb4:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80104cba:	85 c0                	test   %eax,%eax
80104cbc:	74 05                	je     80104cc3 <popcli+0x70>
    sti();
80104cbe:	e8 b4 fd ff ff       	call   80104a77 <sti>
}
80104cc3:	c9                   	leave  
80104cc4:	c3                   	ret    
80104cc5:	00 00                	add    %al,(%eax)
	...

80104cc8 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
80104cc8:	55                   	push   %ebp
80104cc9:	89 e5                	mov    %esp,%ebp
80104ccb:	57                   	push   %edi
80104ccc:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
80104ccd:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104cd0:	8b 55 10             	mov    0x10(%ebp),%edx
80104cd3:	8b 45 0c             	mov    0xc(%ebp),%eax
80104cd6:	89 cb                	mov    %ecx,%ebx
80104cd8:	89 df                	mov    %ebx,%edi
80104cda:	89 d1                	mov    %edx,%ecx
80104cdc:	fc                   	cld    
80104cdd:	f3 aa                	rep stos %al,%es:(%edi)
80104cdf:	89 ca                	mov    %ecx,%edx
80104ce1:	89 fb                	mov    %edi,%ebx
80104ce3:	89 5d 08             	mov    %ebx,0x8(%ebp)
80104ce6:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80104ce9:	5b                   	pop    %ebx
80104cea:	5f                   	pop    %edi
80104ceb:	5d                   	pop    %ebp
80104cec:	c3                   	ret    

80104ced <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
80104ced:	55                   	push   %ebp
80104cee:	89 e5                	mov    %esp,%ebp
80104cf0:	57                   	push   %edi
80104cf1:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
80104cf2:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104cf5:	8b 55 10             	mov    0x10(%ebp),%edx
80104cf8:	8b 45 0c             	mov    0xc(%ebp),%eax
80104cfb:	89 cb                	mov    %ecx,%ebx
80104cfd:	89 df                	mov    %ebx,%edi
80104cff:	89 d1                	mov    %edx,%ecx
80104d01:	fc                   	cld    
80104d02:	f3 ab                	rep stos %eax,%es:(%edi)
80104d04:	89 ca                	mov    %ecx,%edx
80104d06:	89 fb                	mov    %edi,%ebx
80104d08:	89 5d 08             	mov    %ebx,0x8(%ebp)
80104d0b:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80104d0e:	5b                   	pop    %ebx
80104d0f:	5f                   	pop    %edi
80104d10:	5d                   	pop    %ebp
80104d11:	c3                   	ret    

80104d12 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80104d12:	55                   	push   %ebp
80104d13:	89 e5                	mov    %esp,%ebp
80104d15:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
80104d18:	8b 45 08             	mov    0x8(%ebp),%eax
80104d1b:	83 e0 03             	and    $0x3,%eax
80104d1e:	85 c0                	test   %eax,%eax
80104d20:	75 49                	jne    80104d6b <memset+0x59>
80104d22:	8b 45 10             	mov    0x10(%ebp),%eax
80104d25:	83 e0 03             	and    $0x3,%eax
80104d28:	85 c0                	test   %eax,%eax
80104d2a:	75 3f                	jne    80104d6b <memset+0x59>
    c &= 0xFF;
80104d2c:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80104d33:	8b 45 10             	mov    0x10(%ebp),%eax
80104d36:	c1 e8 02             	shr    $0x2,%eax
80104d39:	89 c2                	mov    %eax,%edx
80104d3b:	8b 45 0c             	mov    0xc(%ebp),%eax
80104d3e:	89 c1                	mov    %eax,%ecx
80104d40:	c1 e1 18             	shl    $0x18,%ecx
80104d43:	8b 45 0c             	mov    0xc(%ebp),%eax
80104d46:	c1 e0 10             	shl    $0x10,%eax
80104d49:	09 c1                	or     %eax,%ecx
80104d4b:	8b 45 0c             	mov    0xc(%ebp),%eax
80104d4e:	c1 e0 08             	shl    $0x8,%eax
80104d51:	09 c8                	or     %ecx,%eax
80104d53:	0b 45 0c             	or     0xc(%ebp),%eax
80104d56:	89 54 24 08          	mov    %edx,0x8(%esp)
80104d5a:	89 44 24 04          	mov    %eax,0x4(%esp)
80104d5e:	8b 45 08             	mov    0x8(%ebp),%eax
80104d61:	89 04 24             	mov    %eax,(%esp)
80104d64:	e8 84 ff ff ff       	call   80104ced <stosl>
80104d69:	eb 19                	jmp    80104d84 <memset+0x72>
  } else
    stosb(dst, c, n);
80104d6b:	8b 45 10             	mov    0x10(%ebp),%eax
80104d6e:	89 44 24 08          	mov    %eax,0x8(%esp)
80104d72:	8b 45 0c             	mov    0xc(%ebp),%eax
80104d75:	89 44 24 04          	mov    %eax,0x4(%esp)
80104d79:	8b 45 08             	mov    0x8(%ebp),%eax
80104d7c:	89 04 24             	mov    %eax,(%esp)
80104d7f:	e8 44 ff ff ff       	call   80104cc8 <stosb>
  return dst;
80104d84:	8b 45 08             	mov    0x8(%ebp),%eax
}
80104d87:	c9                   	leave  
80104d88:	c3                   	ret    

80104d89 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80104d89:	55                   	push   %ebp
80104d8a:	89 e5                	mov    %esp,%ebp
80104d8c:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;
  
  s1 = v1;
80104d8f:	8b 45 08             	mov    0x8(%ebp),%eax
80104d92:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
80104d95:	8b 45 0c             	mov    0xc(%ebp),%eax
80104d98:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
80104d9b:	eb 32                	jmp    80104dcf <memcmp+0x46>
    if(*s1 != *s2)
80104d9d:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104da0:	0f b6 10             	movzbl (%eax),%edx
80104da3:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104da6:	0f b6 00             	movzbl (%eax),%eax
80104da9:	38 c2                	cmp    %al,%dl
80104dab:	74 1a                	je     80104dc7 <memcmp+0x3e>
      return *s1 - *s2;
80104dad:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104db0:	0f b6 00             	movzbl (%eax),%eax
80104db3:	0f b6 d0             	movzbl %al,%edx
80104db6:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104db9:	0f b6 00             	movzbl (%eax),%eax
80104dbc:	0f b6 c0             	movzbl %al,%eax
80104dbf:	89 d1                	mov    %edx,%ecx
80104dc1:	29 c1                	sub    %eax,%ecx
80104dc3:	89 c8                	mov    %ecx,%eax
80104dc5:	eb 1c                	jmp    80104de3 <memcmp+0x5a>
    s1++, s2++;
80104dc7:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80104dcb:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80104dcf:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80104dd3:	0f 95 c0             	setne  %al
80104dd6:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80104dda:	84 c0                	test   %al,%al
80104ddc:	75 bf                	jne    80104d9d <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
80104dde:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104de3:	c9                   	leave  
80104de4:	c3                   	ret    

80104de5 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80104de5:	55                   	push   %ebp
80104de6:	89 e5                	mov    %esp,%ebp
80104de8:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
80104deb:	8b 45 0c             	mov    0xc(%ebp),%eax
80104dee:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
80104df1:	8b 45 08             	mov    0x8(%ebp),%eax
80104df4:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
80104df7:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104dfa:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80104dfd:	73 54                	jae    80104e53 <memmove+0x6e>
80104dff:	8b 45 10             	mov    0x10(%ebp),%eax
80104e02:	8b 55 fc             	mov    -0x4(%ebp),%edx
80104e05:	01 d0                	add    %edx,%eax
80104e07:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80104e0a:	76 47                	jbe    80104e53 <memmove+0x6e>
    s += n;
80104e0c:	8b 45 10             	mov    0x10(%ebp),%eax
80104e0f:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
80104e12:	8b 45 10             	mov    0x10(%ebp),%eax
80104e15:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
80104e18:	eb 13                	jmp    80104e2d <memmove+0x48>
      *--d = *--s;
80104e1a:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
80104e1e:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
80104e22:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104e25:	0f b6 10             	movzbl (%eax),%edx
80104e28:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104e2b:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
80104e2d:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80104e31:	0f 95 c0             	setne  %al
80104e34:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80104e38:	84 c0                	test   %al,%al
80104e3a:	75 de                	jne    80104e1a <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80104e3c:	eb 25                	jmp    80104e63 <memmove+0x7e>
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
      *d++ = *s++;
80104e3e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104e41:	0f b6 10             	movzbl (%eax),%edx
80104e44:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104e47:	88 10                	mov    %dl,(%eax)
80104e49:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80104e4d:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80104e51:	eb 01                	jmp    80104e54 <memmove+0x6f>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
80104e53:	90                   	nop
80104e54:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80104e58:	0f 95 c0             	setne  %al
80104e5b:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80104e5f:	84 c0                	test   %al,%al
80104e61:	75 db                	jne    80104e3e <memmove+0x59>
      *d++ = *s++;

  return dst;
80104e63:	8b 45 08             	mov    0x8(%ebp),%eax
}
80104e66:	c9                   	leave  
80104e67:	c3                   	ret    

80104e68 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80104e68:	55                   	push   %ebp
80104e69:	89 e5                	mov    %esp,%ebp
80104e6b:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
80104e6e:	8b 45 10             	mov    0x10(%ebp),%eax
80104e71:	89 44 24 08          	mov    %eax,0x8(%esp)
80104e75:	8b 45 0c             	mov    0xc(%ebp),%eax
80104e78:	89 44 24 04          	mov    %eax,0x4(%esp)
80104e7c:	8b 45 08             	mov    0x8(%ebp),%eax
80104e7f:	89 04 24             	mov    %eax,(%esp)
80104e82:	e8 5e ff ff ff       	call   80104de5 <memmove>
}
80104e87:	c9                   	leave  
80104e88:	c3                   	ret    

80104e89 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80104e89:	55                   	push   %ebp
80104e8a:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
80104e8c:	eb 0c                	jmp    80104e9a <strncmp+0x11>
    n--, p++, q++;
80104e8e:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80104e92:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80104e96:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
80104e9a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80104e9e:	74 1a                	je     80104eba <strncmp+0x31>
80104ea0:	8b 45 08             	mov    0x8(%ebp),%eax
80104ea3:	0f b6 00             	movzbl (%eax),%eax
80104ea6:	84 c0                	test   %al,%al
80104ea8:	74 10                	je     80104eba <strncmp+0x31>
80104eaa:	8b 45 08             	mov    0x8(%ebp),%eax
80104ead:	0f b6 10             	movzbl (%eax),%edx
80104eb0:	8b 45 0c             	mov    0xc(%ebp),%eax
80104eb3:	0f b6 00             	movzbl (%eax),%eax
80104eb6:	38 c2                	cmp    %al,%dl
80104eb8:	74 d4                	je     80104e8e <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
80104eba:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80104ebe:	75 07                	jne    80104ec7 <strncmp+0x3e>
    return 0;
80104ec0:	b8 00 00 00 00       	mov    $0x0,%eax
80104ec5:	eb 18                	jmp    80104edf <strncmp+0x56>
  return (uchar)*p - (uchar)*q;
80104ec7:	8b 45 08             	mov    0x8(%ebp),%eax
80104eca:	0f b6 00             	movzbl (%eax),%eax
80104ecd:	0f b6 d0             	movzbl %al,%edx
80104ed0:	8b 45 0c             	mov    0xc(%ebp),%eax
80104ed3:	0f b6 00             	movzbl (%eax),%eax
80104ed6:	0f b6 c0             	movzbl %al,%eax
80104ed9:	89 d1                	mov    %edx,%ecx
80104edb:	29 c1                	sub    %eax,%ecx
80104edd:	89 c8                	mov    %ecx,%eax
}
80104edf:	5d                   	pop    %ebp
80104ee0:	c3                   	ret    

80104ee1 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80104ee1:	55                   	push   %ebp
80104ee2:	89 e5                	mov    %esp,%ebp
80104ee4:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80104ee7:	8b 45 08             	mov    0x8(%ebp),%eax
80104eea:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
80104eed:	90                   	nop
80104eee:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80104ef2:	0f 9f c0             	setg   %al
80104ef5:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80104ef9:	84 c0                	test   %al,%al
80104efb:	74 30                	je     80104f2d <strncpy+0x4c>
80104efd:	8b 45 0c             	mov    0xc(%ebp),%eax
80104f00:	0f b6 10             	movzbl (%eax),%edx
80104f03:	8b 45 08             	mov    0x8(%ebp),%eax
80104f06:	88 10                	mov    %dl,(%eax)
80104f08:	8b 45 08             	mov    0x8(%ebp),%eax
80104f0b:	0f b6 00             	movzbl (%eax),%eax
80104f0e:	84 c0                	test   %al,%al
80104f10:	0f 95 c0             	setne  %al
80104f13:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80104f17:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
80104f1b:	84 c0                	test   %al,%al
80104f1d:	75 cf                	jne    80104eee <strncpy+0xd>
    ;
  while(n-- > 0)
80104f1f:	eb 0c                	jmp    80104f2d <strncpy+0x4c>
    *s++ = 0;
80104f21:	8b 45 08             	mov    0x8(%ebp),%eax
80104f24:	c6 00 00             	movb   $0x0,(%eax)
80104f27:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80104f2b:	eb 01                	jmp    80104f2e <strncpy+0x4d>
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
80104f2d:	90                   	nop
80104f2e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80104f32:	0f 9f c0             	setg   %al
80104f35:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80104f39:	84 c0                	test   %al,%al
80104f3b:	75 e4                	jne    80104f21 <strncpy+0x40>
    *s++ = 0;
  return os;
80104f3d:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80104f40:	c9                   	leave  
80104f41:	c3                   	ret    

80104f42 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
80104f42:	55                   	push   %ebp
80104f43:	89 e5                	mov    %esp,%ebp
80104f45:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80104f48:	8b 45 08             	mov    0x8(%ebp),%eax
80104f4b:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
80104f4e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80104f52:	7f 05                	jg     80104f59 <safestrcpy+0x17>
    return os;
80104f54:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104f57:	eb 35                	jmp    80104f8e <safestrcpy+0x4c>
  while(--n > 0 && (*s++ = *t++) != 0)
80104f59:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80104f5d:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80104f61:	7e 22                	jle    80104f85 <safestrcpy+0x43>
80104f63:	8b 45 0c             	mov    0xc(%ebp),%eax
80104f66:	0f b6 10             	movzbl (%eax),%edx
80104f69:	8b 45 08             	mov    0x8(%ebp),%eax
80104f6c:	88 10                	mov    %dl,(%eax)
80104f6e:	8b 45 08             	mov    0x8(%ebp),%eax
80104f71:	0f b6 00             	movzbl (%eax),%eax
80104f74:	84 c0                	test   %al,%al
80104f76:	0f 95 c0             	setne  %al
80104f79:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80104f7d:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
80104f81:	84 c0                	test   %al,%al
80104f83:	75 d4                	jne    80104f59 <safestrcpy+0x17>
    ;
  *s = 0;
80104f85:	8b 45 08             	mov    0x8(%ebp),%eax
80104f88:	c6 00 00             	movb   $0x0,(%eax)
  return os;
80104f8b:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80104f8e:	c9                   	leave  
80104f8f:	c3                   	ret    

80104f90 <strlen>:

int
strlen(const char *s)
{
80104f90:	55                   	push   %ebp
80104f91:	89 e5                	mov    %esp,%ebp
80104f93:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
80104f96:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80104f9d:	eb 04                	jmp    80104fa3 <strlen+0x13>
80104f9f:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80104fa3:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104fa6:	03 45 08             	add    0x8(%ebp),%eax
80104fa9:	0f b6 00             	movzbl (%eax),%eax
80104fac:	84 c0                	test   %al,%al
80104fae:	75 ef                	jne    80104f9f <strlen+0xf>
    ;
  return n;
80104fb0:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80104fb3:	c9                   	leave  
80104fb4:	c3                   	ret    
80104fb5:	00 00                	add    %al,(%eax)
	...

80104fb8 <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
80104fb8:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80104fbc:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
80104fc0:	55                   	push   %ebp
  pushl %ebx
80104fc1:	53                   	push   %ebx
  pushl %esi
80104fc2:	56                   	push   %esi
  pushl %edi
80104fc3:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80104fc4:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80104fc6:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
80104fc8:	5f                   	pop    %edi
  popl %esi
80104fc9:	5e                   	pop    %esi
  popl %ebx
80104fca:	5b                   	pop    %ebx
  popl %ebp
80104fcb:	5d                   	pop    %ebp
  ret
80104fcc:	c3                   	ret    
80104fcd:	00 00                	add    %al,(%eax)
	...

80104fd0 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
80104fd0:	55                   	push   %ebp
80104fd1:	89 e5                	mov    %esp,%ebp
  if(addr >= proc->sz || addr+4 > proc->sz)
80104fd3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104fd9:	8b 00                	mov    (%eax),%eax
80104fdb:	3b 45 08             	cmp    0x8(%ebp),%eax
80104fde:	76 12                	jbe    80104ff2 <fetchint+0x22>
80104fe0:	8b 45 08             	mov    0x8(%ebp),%eax
80104fe3:	8d 50 04             	lea    0x4(%eax),%edx
80104fe6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104fec:	8b 00                	mov    (%eax),%eax
80104fee:	39 c2                	cmp    %eax,%edx
80104ff0:	76 07                	jbe    80104ff9 <fetchint+0x29>
    return -1;
80104ff2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ff7:	eb 0f                	jmp    80105008 <fetchint+0x38>
  *ip = *(int*)(addr);
80104ff9:	8b 45 08             	mov    0x8(%ebp),%eax
80104ffc:	8b 10                	mov    (%eax),%edx
80104ffe:	8b 45 0c             	mov    0xc(%ebp),%eax
80105001:	89 10                	mov    %edx,(%eax)
  return 0;
80105003:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105008:	5d                   	pop    %ebp
80105009:	c3                   	ret    

8010500a <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
8010500a:	55                   	push   %ebp
8010500b:	89 e5                	mov    %esp,%ebp
8010500d:	83 ec 10             	sub    $0x10,%esp
  char *s, *ep;

  if(addr >= proc->sz)
80105010:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105016:	8b 00                	mov    (%eax),%eax
80105018:	3b 45 08             	cmp    0x8(%ebp),%eax
8010501b:	77 07                	ja     80105024 <fetchstr+0x1a>
    return -1;
8010501d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105022:	eb 48                	jmp    8010506c <fetchstr+0x62>
  *pp = (char*)addr;
80105024:	8b 55 08             	mov    0x8(%ebp),%edx
80105027:	8b 45 0c             	mov    0xc(%ebp),%eax
8010502a:	89 10                	mov    %edx,(%eax)
  ep = (char*)proc->sz;
8010502c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105032:	8b 00                	mov    (%eax),%eax
80105034:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(s = *pp; s < ep; s++)
80105037:	8b 45 0c             	mov    0xc(%ebp),%eax
8010503a:	8b 00                	mov    (%eax),%eax
8010503c:	89 45 fc             	mov    %eax,-0x4(%ebp)
8010503f:	eb 1e                	jmp    8010505f <fetchstr+0x55>
    if(*s == 0)
80105041:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105044:	0f b6 00             	movzbl (%eax),%eax
80105047:	84 c0                	test   %al,%al
80105049:	75 10                	jne    8010505b <fetchstr+0x51>
      return s - *pp;
8010504b:	8b 55 fc             	mov    -0x4(%ebp),%edx
8010504e:	8b 45 0c             	mov    0xc(%ebp),%eax
80105051:	8b 00                	mov    (%eax),%eax
80105053:	89 d1                	mov    %edx,%ecx
80105055:	29 c1                	sub    %eax,%ecx
80105057:	89 c8                	mov    %ecx,%eax
80105059:	eb 11                	jmp    8010506c <fetchstr+0x62>

  if(addr >= proc->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)proc->sz;
  for(s = *pp; s < ep; s++)
8010505b:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010505f:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105062:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105065:	72 da                	jb     80105041 <fetchstr+0x37>
    if(*s == 0)
      return s - *pp;
  return -1;
80105067:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010506c:	c9                   	leave  
8010506d:	c3                   	ret    

8010506e <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
8010506e:	55                   	push   %ebp
8010506f:	89 e5                	mov    %esp,%ebp
80105071:	83 ec 08             	sub    $0x8,%esp
  return fetchint(proc->tf->esp + 4 + 4*n, ip);
80105074:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010507a:	8b 40 18             	mov    0x18(%eax),%eax
8010507d:	8b 50 44             	mov    0x44(%eax),%edx
80105080:	8b 45 08             	mov    0x8(%ebp),%eax
80105083:	c1 e0 02             	shl    $0x2,%eax
80105086:	01 d0                	add    %edx,%eax
80105088:	8d 50 04             	lea    0x4(%eax),%edx
8010508b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010508e:	89 44 24 04          	mov    %eax,0x4(%esp)
80105092:	89 14 24             	mov    %edx,(%esp)
80105095:	e8 36 ff ff ff       	call   80104fd0 <fetchint>
}
8010509a:	c9                   	leave  
8010509b:	c3                   	ret    

8010509c <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
8010509c:	55                   	push   %ebp
8010509d:	89 e5                	mov    %esp,%ebp
8010509f:	83 ec 18             	sub    $0x18,%esp
  int i;
  
  if(argint(n, &i) < 0)
801050a2:	8d 45 fc             	lea    -0x4(%ebp),%eax
801050a5:	89 44 24 04          	mov    %eax,0x4(%esp)
801050a9:	8b 45 08             	mov    0x8(%ebp),%eax
801050ac:	89 04 24             	mov    %eax,(%esp)
801050af:	e8 ba ff ff ff       	call   8010506e <argint>
801050b4:	85 c0                	test   %eax,%eax
801050b6:	79 07                	jns    801050bf <argptr+0x23>
    return -1;
801050b8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801050bd:	eb 3d                	jmp    801050fc <argptr+0x60>
  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
801050bf:	8b 45 fc             	mov    -0x4(%ebp),%eax
801050c2:	89 c2                	mov    %eax,%edx
801050c4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050ca:	8b 00                	mov    (%eax),%eax
801050cc:	39 c2                	cmp    %eax,%edx
801050ce:	73 16                	jae    801050e6 <argptr+0x4a>
801050d0:	8b 45 fc             	mov    -0x4(%ebp),%eax
801050d3:	89 c2                	mov    %eax,%edx
801050d5:	8b 45 10             	mov    0x10(%ebp),%eax
801050d8:	01 c2                	add    %eax,%edx
801050da:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050e0:	8b 00                	mov    (%eax),%eax
801050e2:	39 c2                	cmp    %eax,%edx
801050e4:	76 07                	jbe    801050ed <argptr+0x51>
    return -1;
801050e6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801050eb:	eb 0f                	jmp    801050fc <argptr+0x60>
  *pp = (char*)i;
801050ed:	8b 45 fc             	mov    -0x4(%ebp),%eax
801050f0:	89 c2                	mov    %eax,%edx
801050f2:	8b 45 0c             	mov    0xc(%ebp),%eax
801050f5:	89 10                	mov    %edx,(%eax)
  return 0;
801050f7:	b8 00 00 00 00       	mov    $0x0,%eax
}
801050fc:	c9                   	leave  
801050fd:	c3                   	ret    

801050fe <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
801050fe:	55                   	push   %ebp
801050ff:	89 e5                	mov    %esp,%ebp
80105101:	83 ec 18             	sub    $0x18,%esp
  int addr;
  if(argint(n, &addr) < 0)
80105104:	8d 45 fc             	lea    -0x4(%ebp),%eax
80105107:	89 44 24 04          	mov    %eax,0x4(%esp)
8010510b:	8b 45 08             	mov    0x8(%ebp),%eax
8010510e:	89 04 24             	mov    %eax,(%esp)
80105111:	e8 58 ff ff ff       	call   8010506e <argint>
80105116:	85 c0                	test   %eax,%eax
80105118:	79 07                	jns    80105121 <argstr+0x23>
    return -1;
8010511a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010511f:	eb 12                	jmp    80105133 <argstr+0x35>
  return fetchstr(addr, pp);
80105121:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105124:	8b 55 0c             	mov    0xc(%ebp),%edx
80105127:	89 54 24 04          	mov    %edx,0x4(%esp)
8010512b:	89 04 24             	mov    %eax,(%esp)
8010512e:	e8 d7 fe ff ff       	call   8010500a <fetchstr>
}
80105133:	c9                   	leave  
80105134:	c3                   	ret    

80105135 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
80105135:	55                   	push   %ebp
80105136:	89 e5                	mov    %esp,%ebp
80105138:	53                   	push   %ebx
80105139:	83 ec 24             	sub    $0x24,%esp
  int num;

  num = proc->tf->eax;
8010513c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105142:	8b 40 18             	mov    0x18(%eax),%eax
80105145:	8b 40 1c             	mov    0x1c(%eax),%eax
80105148:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
8010514b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010514f:	7e 30                	jle    80105181 <syscall+0x4c>
80105151:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105154:	83 f8 15             	cmp    $0x15,%eax
80105157:	77 28                	ja     80105181 <syscall+0x4c>
80105159:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010515c:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
80105163:	85 c0                	test   %eax,%eax
80105165:	74 1a                	je     80105181 <syscall+0x4c>
    proc->tf->eax = syscalls[num]();
80105167:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010516d:	8b 58 18             	mov    0x18(%eax),%ebx
80105170:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105173:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
8010517a:	ff d0                	call   *%eax
8010517c:	89 43 1c             	mov    %eax,0x1c(%ebx)
8010517f:	eb 3d                	jmp    801051be <syscall+0x89>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
80105181:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105187:	8d 48 6c             	lea    0x6c(%eax),%ecx
8010518a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax

  num = proc->tf->eax;
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
80105190:	8b 40 10             	mov    0x10(%eax),%eax
80105193:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105196:	89 54 24 0c          	mov    %edx,0xc(%esp)
8010519a:	89 4c 24 08          	mov    %ecx,0x8(%esp)
8010519e:	89 44 24 04          	mov    %eax,0x4(%esp)
801051a2:	c7 04 24 47 84 10 80 	movl   $0x80108447,(%esp)
801051a9:	e8 f3 b1 ff ff       	call   801003a1 <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
801051ae:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801051b4:	8b 40 18             	mov    0x18(%eax),%eax
801051b7:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
801051be:	83 c4 24             	add    $0x24,%esp
801051c1:	5b                   	pop    %ebx
801051c2:	5d                   	pop    %ebp
801051c3:	c3                   	ret    

801051c4 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
801051c4:	55                   	push   %ebp
801051c5:	89 e5                	mov    %esp,%ebp
801051c7:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
801051ca:	8d 45 f0             	lea    -0x10(%ebp),%eax
801051cd:	89 44 24 04          	mov    %eax,0x4(%esp)
801051d1:	8b 45 08             	mov    0x8(%ebp),%eax
801051d4:	89 04 24             	mov    %eax,(%esp)
801051d7:	e8 92 fe ff ff       	call   8010506e <argint>
801051dc:	85 c0                	test   %eax,%eax
801051de:	79 07                	jns    801051e7 <argfd+0x23>
    return -1;
801051e0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801051e5:	eb 50                	jmp    80105237 <argfd+0x73>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
801051e7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801051ea:	85 c0                	test   %eax,%eax
801051ec:	78 21                	js     8010520f <argfd+0x4b>
801051ee:	8b 45 f0             	mov    -0x10(%ebp),%eax
801051f1:	83 f8 0f             	cmp    $0xf,%eax
801051f4:	7f 19                	jg     8010520f <argfd+0x4b>
801051f6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801051fc:	8b 55 f0             	mov    -0x10(%ebp),%edx
801051ff:	83 c2 08             	add    $0x8,%edx
80105202:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105206:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105209:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010520d:	75 07                	jne    80105216 <argfd+0x52>
    return -1;
8010520f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105214:	eb 21                	jmp    80105237 <argfd+0x73>
  if(pfd)
80105216:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
8010521a:	74 08                	je     80105224 <argfd+0x60>
    *pfd = fd;
8010521c:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010521f:	8b 45 0c             	mov    0xc(%ebp),%eax
80105222:	89 10                	mov    %edx,(%eax)
  if(pf)
80105224:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105228:	74 08                	je     80105232 <argfd+0x6e>
    *pf = f;
8010522a:	8b 45 10             	mov    0x10(%ebp),%eax
8010522d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105230:	89 10                	mov    %edx,(%eax)
  return 0;
80105232:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105237:	c9                   	leave  
80105238:	c3                   	ret    

80105239 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
80105239:	55                   	push   %ebp
8010523a:	89 e5                	mov    %esp,%ebp
8010523c:	83 ec 10             	sub    $0x10,%esp
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
8010523f:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80105246:	eb 30                	jmp    80105278 <fdalloc+0x3f>
    if(proc->ofile[fd] == 0){
80105248:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010524e:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105251:	83 c2 08             	add    $0x8,%edx
80105254:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105258:	85 c0                	test   %eax,%eax
8010525a:	75 18                	jne    80105274 <fdalloc+0x3b>
      proc->ofile[fd] = f;
8010525c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105262:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105265:	8d 4a 08             	lea    0x8(%edx),%ecx
80105268:	8b 55 08             	mov    0x8(%ebp),%edx
8010526b:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
8010526f:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105272:	eb 0f                	jmp    80105283 <fdalloc+0x4a>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80105274:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105278:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
8010527c:	7e ca                	jle    80105248 <fdalloc+0xf>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
8010527e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105283:	c9                   	leave  
80105284:	c3                   	ret    

80105285 <sys_dup>:

int
sys_dup(void)
{
80105285:	55                   	push   %ebp
80105286:	89 e5                	mov    %esp,%ebp
80105288:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
8010528b:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010528e:	89 44 24 08          	mov    %eax,0x8(%esp)
80105292:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105299:	00 
8010529a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801052a1:	e8 1e ff ff ff       	call   801051c4 <argfd>
801052a6:	85 c0                	test   %eax,%eax
801052a8:	79 07                	jns    801052b1 <sys_dup+0x2c>
    return -1;
801052aa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801052af:	eb 29                	jmp    801052da <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
801052b1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801052b4:	89 04 24             	mov    %eax,(%esp)
801052b7:	e8 7d ff ff ff       	call   80105239 <fdalloc>
801052bc:	89 45 f4             	mov    %eax,-0xc(%ebp)
801052bf:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801052c3:	79 07                	jns    801052cc <sys_dup+0x47>
    return -1;
801052c5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801052ca:	eb 0e                	jmp    801052da <sys_dup+0x55>
  filedup(f);
801052cc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801052cf:	89 04 24             	mov    %eax,(%esp)
801052d2:	e8 9d bc ff ff       	call   80100f74 <filedup>
  return fd;
801052d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801052da:	c9                   	leave  
801052db:	c3                   	ret    

801052dc <sys_read>:

int
sys_read(void)
{
801052dc:	55                   	push   %ebp
801052dd:	89 e5                	mov    %esp,%ebp
801052df:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801052e2:	8d 45 f4             	lea    -0xc(%ebp),%eax
801052e5:	89 44 24 08          	mov    %eax,0x8(%esp)
801052e9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801052f0:	00 
801052f1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801052f8:	e8 c7 fe ff ff       	call   801051c4 <argfd>
801052fd:	85 c0                	test   %eax,%eax
801052ff:	78 35                	js     80105336 <sys_read+0x5a>
80105301:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105304:	89 44 24 04          	mov    %eax,0x4(%esp)
80105308:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
8010530f:	e8 5a fd ff ff       	call   8010506e <argint>
80105314:	85 c0                	test   %eax,%eax
80105316:	78 1e                	js     80105336 <sys_read+0x5a>
80105318:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010531b:	89 44 24 08          	mov    %eax,0x8(%esp)
8010531f:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105322:	89 44 24 04          	mov    %eax,0x4(%esp)
80105326:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010532d:	e8 6a fd ff ff       	call   8010509c <argptr>
80105332:	85 c0                	test   %eax,%eax
80105334:	79 07                	jns    8010533d <sys_read+0x61>
    return -1;
80105336:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010533b:	eb 19                	jmp    80105356 <sys_read+0x7a>
  return fileread(f, p, n);
8010533d:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80105340:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105343:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105346:	89 4c 24 08          	mov    %ecx,0x8(%esp)
8010534a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010534e:	89 04 24             	mov    %eax,(%esp)
80105351:	e8 8b bd ff ff       	call   801010e1 <fileread>
}
80105356:	c9                   	leave  
80105357:	c3                   	ret    

80105358 <sys_write>:

int
sys_write(void)
{
80105358:	55                   	push   %ebp
80105359:	89 e5                	mov    %esp,%ebp
8010535b:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
8010535e:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105361:	89 44 24 08          	mov    %eax,0x8(%esp)
80105365:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010536c:	00 
8010536d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105374:	e8 4b fe ff ff       	call   801051c4 <argfd>
80105379:	85 c0                	test   %eax,%eax
8010537b:	78 35                	js     801053b2 <sys_write+0x5a>
8010537d:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105380:	89 44 24 04          	mov    %eax,0x4(%esp)
80105384:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
8010538b:	e8 de fc ff ff       	call   8010506e <argint>
80105390:	85 c0                	test   %eax,%eax
80105392:	78 1e                	js     801053b2 <sys_write+0x5a>
80105394:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105397:	89 44 24 08          	mov    %eax,0x8(%esp)
8010539b:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010539e:	89 44 24 04          	mov    %eax,0x4(%esp)
801053a2:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801053a9:	e8 ee fc ff ff       	call   8010509c <argptr>
801053ae:	85 c0                	test   %eax,%eax
801053b0:	79 07                	jns    801053b9 <sys_write+0x61>
    return -1;
801053b2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801053b7:	eb 19                	jmp    801053d2 <sys_write+0x7a>
  return filewrite(f, p, n);
801053b9:	8b 4d f0             	mov    -0x10(%ebp),%ecx
801053bc:	8b 55 ec             	mov    -0x14(%ebp),%edx
801053bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053c2:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801053c6:	89 54 24 04          	mov    %edx,0x4(%esp)
801053ca:	89 04 24             	mov    %eax,(%esp)
801053cd:	e8 cb bd ff ff       	call   8010119d <filewrite>
}
801053d2:	c9                   	leave  
801053d3:	c3                   	ret    

801053d4 <sys_close>:

int
sys_close(void)
{
801053d4:	55                   	push   %ebp
801053d5:	89 e5                	mov    %esp,%ebp
801053d7:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
801053da:	8d 45 f0             	lea    -0x10(%ebp),%eax
801053dd:	89 44 24 08          	mov    %eax,0x8(%esp)
801053e1:	8d 45 f4             	lea    -0xc(%ebp),%eax
801053e4:	89 44 24 04          	mov    %eax,0x4(%esp)
801053e8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801053ef:	e8 d0 fd ff ff       	call   801051c4 <argfd>
801053f4:	85 c0                	test   %eax,%eax
801053f6:	79 07                	jns    801053ff <sys_close+0x2b>
    return -1;
801053f8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801053fd:	eb 24                	jmp    80105423 <sys_close+0x4f>
  proc->ofile[fd] = 0;
801053ff:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105405:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105408:	83 c2 08             	add    $0x8,%edx
8010540b:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80105412:	00 
  fileclose(f);
80105413:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105416:	89 04 24             	mov    %eax,(%esp)
80105419:	e8 9e bb ff ff       	call   80100fbc <fileclose>
  return 0;
8010541e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105423:	c9                   	leave  
80105424:	c3                   	ret    

80105425 <sys_fstat>:

int
sys_fstat(void)
{
80105425:	55                   	push   %ebp
80105426:	89 e5                	mov    %esp,%ebp
80105428:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
8010542b:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010542e:	89 44 24 08          	mov    %eax,0x8(%esp)
80105432:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105439:	00 
8010543a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105441:	e8 7e fd ff ff       	call   801051c4 <argfd>
80105446:	85 c0                	test   %eax,%eax
80105448:	78 1f                	js     80105469 <sys_fstat+0x44>
8010544a:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80105451:	00 
80105452:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105455:	89 44 24 04          	mov    %eax,0x4(%esp)
80105459:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105460:	e8 37 fc ff ff       	call   8010509c <argptr>
80105465:	85 c0                	test   %eax,%eax
80105467:	79 07                	jns    80105470 <sys_fstat+0x4b>
    return -1;
80105469:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010546e:	eb 12                	jmp    80105482 <sys_fstat+0x5d>
  return filestat(f, st);
80105470:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105473:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105476:	89 54 24 04          	mov    %edx,0x4(%esp)
8010547a:	89 04 24             	mov    %eax,(%esp)
8010547d:	e8 10 bc ff ff       	call   80101092 <filestat>
}
80105482:	c9                   	leave  
80105483:	c3                   	ret    

80105484 <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
80105484:	55                   	push   %ebp
80105485:	89 e5                	mov    %esp,%ebp
80105487:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
8010548a:	8d 45 d8             	lea    -0x28(%ebp),%eax
8010548d:	89 44 24 04          	mov    %eax,0x4(%esp)
80105491:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105498:	e8 61 fc ff ff       	call   801050fe <argstr>
8010549d:	85 c0                	test   %eax,%eax
8010549f:	78 17                	js     801054b8 <sys_link+0x34>
801054a1:	8d 45 dc             	lea    -0x24(%ebp),%eax
801054a4:	89 44 24 04          	mov    %eax,0x4(%esp)
801054a8:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801054af:	e8 4a fc ff ff       	call   801050fe <argstr>
801054b4:	85 c0                	test   %eax,%eax
801054b6:	79 0a                	jns    801054c2 <sys_link+0x3e>
    return -1;
801054b8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801054bd:	e9 3c 01 00 00       	jmp    801055fe <sys_link+0x17a>
  if((ip = namei(old)) == 0)
801054c2:	8b 45 d8             	mov    -0x28(%ebp),%eax
801054c5:	89 04 24             	mov    %eax,(%esp)
801054c8:	e8 35 cf ff ff       	call   80102402 <namei>
801054cd:	89 45 f4             	mov    %eax,-0xc(%ebp)
801054d0:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801054d4:	75 0a                	jne    801054e0 <sys_link+0x5c>
    return -1;
801054d6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801054db:	e9 1e 01 00 00       	jmp    801055fe <sys_link+0x17a>

  begin_trans();
801054e0:	e8 30 dd ff ff       	call   80103215 <begin_trans>

  ilock(ip);
801054e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801054e8:	89 04 24             	mov    %eax,(%esp)
801054eb:	e8 70 c3 ff ff       	call   80101860 <ilock>
  if(ip->type == T_DIR){
801054f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801054f3:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801054f7:	66 83 f8 01          	cmp    $0x1,%ax
801054fb:	75 1a                	jne    80105517 <sys_link+0x93>
    iunlockput(ip);
801054fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105500:	89 04 24             	mov    %eax,(%esp)
80105503:	e8 dc c5 ff ff       	call   80101ae4 <iunlockput>
    commit_trans();
80105508:	e8 51 dd ff ff       	call   8010325e <commit_trans>
    return -1;
8010550d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105512:	e9 e7 00 00 00       	jmp    801055fe <sys_link+0x17a>
  }

  ip->nlink++;
80105517:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010551a:	0f b7 40 16          	movzwl 0x16(%eax),%eax
8010551e:	8d 50 01             	lea    0x1(%eax),%edx
80105521:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105524:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80105528:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010552b:	89 04 24             	mov    %eax,(%esp)
8010552e:	e8 71 c1 ff ff       	call   801016a4 <iupdate>
  iunlock(ip);
80105533:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105536:	89 04 24             	mov    %eax,(%esp)
80105539:	e8 70 c4 ff ff       	call   801019ae <iunlock>

  if((dp = nameiparent(new, name)) == 0)
8010553e:	8b 45 dc             	mov    -0x24(%ebp),%eax
80105541:	8d 55 e2             	lea    -0x1e(%ebp),%edx
80105544:	89 54 24 04          	mov    %edx,0x4(%esp)
80105548:	89 04 24             	mov    %eax,(%esp)
8010554b:	e8 d4 ce ff ff       	call   80102424 <nameiparent>
80105550:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105553:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105557:	74 68                	je     801055c1 <sys_link+0x13d>
    goto bad;
  ilock(dp);
80105559:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010555c:	89 04 24             	mov    %eax,(%esp)
8010555f:	e8 fc c2 ff ff       	call   80101860 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
80105564:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105567:	8b 10                	mov    (%eax),%edx
80105569:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010556c:	8b 00                	mov    (%eax),%eax
8010556e:	39 c2                	cmp    %eax,%edx
80105570:	75 20                	jne    80105592 <sys_link+0x10e>
80105572:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105575:	8b 40 04             	mov    0x4(%eax),%eax
80105578:	89 44 24 08          	mov    %eax,0x8(%esp)
8010557c:	8d 45 e2             	lea    -0x1e(%ebp),%eax
8010557f:	89 44 24 04          	mov    %eax,0x4(%esp)
80105583:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105586:	89 04 24             	mov    %eax,(%esp)
80105589:	e8 b3 cb ff ff       	call   80102141 <dirlink>
8010558e:	85 c0                	test   %eax,%eax
80105590:	79 0d                	jns    8010559f <sys_link+0x11b>
    iunlockput(dp);
80105592:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105595:	89 04 24             	mov    %eax,(%esp)
80105598:	e8 47 c5 ff ff       	call   80101ae4 <iunlockput>
    goto bad;
8010559d:	eb 23                	jmp    801055c2 <sys_link+0x13e>
  }
  iunlockput(dp);
8010559f:	8b 45 f0             	mov    -0x10(%ebp),%eax
801055a2:	89 04 24             	mov    %eax,(%esp)
801055a5:	e8 3a c5 ff ff       	call   80101ae4 <iunlockput>
  iput(ip);
801055aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055ad:	89 04 24             	mov    %eax,(%esp)
801055b0:	e8 5e c4 ff ff       	call   80101a13 <iput>

  commit_trans();
801055b5:	e8 a4 dc ff ff       	call   8010325e <commit_trans>

  return 0;
801055ba:	b8 00 00 00 00       	mov    $0x0,%eax
801055bf:	eb 3d                	jmp    801055fe <sys_link+0x17a>
  ip->nlink++;
  iupdate(ip);
  iunlock(ip);

  if((dp = nameiparent(new, name)) == 0)
    goto bad;
801055c1:	90                   	nop
  commit_trans();

  return 0;

bad:
  ilock(ip);
801055c2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055c5:	89 04 24             	mov    %eax,(%esp)
801055c8:	e8 93 c2 ff ff       	call   80101860 <ilock>
  ip->nlink--;
801055cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055d0:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801055d4:	8d 50 ff             	lea    -0x1(%eax),%edx
801055d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055da:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801055de:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055e1:	89 04 24             	mov    %eax,(%esp)
801055e4:	e8 bb c0 ff ff       	call   801016a4 <iupdate>
  iunlockput(ip);
801055e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055ec:	89 04 24             	mov    %eax,(%esp)
801055ef:	e8 f0 c4 ff ff       	call   80101ae4 <iunlockput>
  commit_trans();
801055f4:	e8 65 dc ff ff       	call   8010325e <commit_trans>
  return -1;
801055f9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801055fe:	c9                   	leave  
801055ff:	c3                   	ret    

80105600 <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
80105600:	55                   	push   %ebp
80105601:	89 e5                	mov    %esp,%ebp
80105603:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80105606:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
8010560d:	eb 4b                	jmp    8010565a <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010560f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105612:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80105619:	00 
8010561a:	89 44 24 08          	mov    %eax,0x8(%esp)
8010561e:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105621:	89 44 24 04          	mov    %eax,0x4(%esp)
80105625:	8b 45 08             	mov    0x8(%ebp),%eax
80105628:	89 04 24             	mov    %eax,(%esp)
8010562b:	e8 26 c7 ff ff       	call   80101d56 <readi>
80105630:	83 f8 10             	cmp    $0x10,%eax
80105633:	74 0c                	je     80105641 <isdirempty+0x41>
      panic("isdirempty: readi");
80105635:	c7 04 24 63 84 10 80 	movl   $0x80108463,(%esp)
8010563c:	e8 fc ae ff ff       	call   8010053d <panic>
    if(de.inum != 0)
80105641:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
80105645:	66 85 c0             	test   %ax,%ax
80105648:	74 07                	je     80105651 <isdirempty+0x51>
      return 0;
8010564a:	b8 00 00 00 00       	mov    $0x0,%eax
8010564f:	eb 1b                	jmp    8010566c <isdirempty+0x6c>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80105651:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105654:	83 c0 10             	add    $0x10,%eax
80105657:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010565a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010565d:	8b 45 08             	mov    0x8(%ebp),%eax
80105660:	8b 40 18             	mov    0x18(%eax),%eax
80105663:	39 c2                	cmp    %eax,%edx
80105665:	72 a8                	jb     8010560f <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
80105667:	b8 01 00 00 00       	mov    $0x1,%eax
}
8010566c:	c9                   	leave  
8010566d:	c3                   	ret    

8010566e <sys_unlink>:

//PAGEBREAK!
int
sys_unlink(void)
{
8010566e:	55                   	push   %ebp
8010566f:	89 e5                	mov    %esp,%ebp
80105671:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
80105674:	8d 45 cc             	lea    -0x34(%ebp),%eax
80105677:	89 44 24 04          	mov    %eax,0x4(%esp)
8010567b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105682:	e8 77 fa ff ff       	call   801050fe <argstr>
80105687:	85 c0                	test   %eax,%eax
80105689:	79 0a                	jns    80105695 <sys_unlink+0x27>
    return -1;
8010568b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105690:	e9 aa 01 00 00       	jmp    8010583f <sys_unlink+0x1d1>
  if((dp = nameiparent(path, name)) == 0)
80105695:	8b 45 cc             	mov    -0x34(%ebp),%eax
80105698:	8d 55 d2             	lea    -0x2e(%ebp),%edx
8010569b:	89 54 24 04          	mov    %edx,0x4(%esp)
8010569f:	89 04 24             	mov    %eax,(%esp)
801056a2:	e8 7d cd ff ff       	call   80102424 <nameiparent>
801056a7:	89 45 f4             	mov    %eax,-0xc(%ebp)
801056aa:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801056ae:	75 0a                	jne    801056ba <sys_unlink+0x4c>
    return -1;
801056b0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801056b5:	e9 85 01 00 00       	jmp    8010583f <sys_unlink+0x1d1>

  begin_trans();
801056ba:	e8 56 db ff ff       	call   80103215 <begin_trans>

  ilock(dp);
801056bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801056c2:	89 04 24             	mov    %eax,(%esp)
801056c5:	e8 96 c1 ff ff       	call   80101860 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
801056ca:	c7 44 24 04 75 84 10 	movl   $0x80108475,0x4(%esp)
801056d1:	80 
801056d2:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801056d5:	89 04 24             	mov    %eax,(%esp)
801056d8:	e8 7a c9 ff ff       	call   80102057 <namecmp>
801056dd:	85 c0                	test   %eax,%eax
801056df:	0f 84 45 01 00 00    	je     8010582a <sys_unlink+0x1bc>
801056e5:	c7 44 24 04 77 84 10 	movl   $0x80108477,0x4(%esp)
801056ec:	80 
801056ed:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801056f0:	89 04 24             	mov    %eax,(%esp)
801056f3:	e8 5f c9 ff ff       	call   80102057 <namecmp>
801056f8:	85 c0                	test   %eax,%eax
801056fa:	0f 84 2a 01 00 00    	je     8010582a <sys_unlink+0x1bc>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
80105700:	8d 45 c8             	lea    -0x38(%ebp),%eax
80105703:	89 44 24 08          	mov    %eax,0x8(%esp)
80105707:	8d 45 d2             	lea    -0x2e(%ebp),%eax
8010570a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010570e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105711:	89 04 24             	mov    %eax,(%esp)
80105714:	e8 60 c9 ff ff       	call   80102079 <dirlookup>
80105719:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010571c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105720:	0f 84 03 01 00 00    	je     80105829 <sys_unlink+0x1bb>
    goto bad;
  ilock(ip);
80105726:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105729:	89 04 24             	mov    %eax,(%esp)
8010572c:	e8 2f c1 ff ff       	call   80101860 <ilock>

  if(ip->nlink < 1)
80105731:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105734:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105738:	66 85 c0             	test   %ax,%ax
8010573b:	7f 0c                	jg     80105749 <sys_unlink+0xdb>
    panic("unlink: nlink < 1");
8010573d:	c7 04 24 7a 84 10 80 	movl   $0x8010847a,(%esp)
80105744:	e8 f4 ad ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80105749:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010574c:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105750:	66 83 f8 01          	cmp    $0x1,%ax
80105754:	75 1f                	jne    80105775 <sys_unlink+0x107>
80105756:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105759:	89 04 24             	mov    %eax,(%esp)
8010575c:	e8 9f fe ff ff       	call   80105600 <isdirempty>
80105761:	85 c0                	test   %eax,%eax
80105763:	75 10                	jne    80105775 <sys_unlink+0x107>
    iunlockput(ip);
80105765:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105768:	89 04 24             	mov    %eax,(%esp)
8010576b:	e8 74 c3 ff ff       	call   80101ae4 <iunlockput>
    goto bad;
80105770:	e9 b5 00 00 00       	jmp    8010582a <sys_unlink+0x1bc>
  }

  memset(&de, 0, sizeof(de));
80105775:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
8010577c:	00 
8010577d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105784:	00 
80105785:	8d 45 e0             	lea    -0x20(%ebp),%eax
80105788:	89 04 24             	mov    %eax,(%esp)
8010578b:	e8 82 f5 ff ff       	call   80104d12 <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80105790:	8b 45 c8             	mov    -0x38(%ebp),%eax
80105793:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
8010579a:	00 
8010579b:	89 44 24 08          	mov    %eax,0x8(%esp)
8010579f:	8d 45 e0             	lea    -0x20(%ebp),%eax
801057a2:	89 44 24 04          	mov    %eax,0x4(%esp)
801057a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057a9:	89 04 24             	mov    %eax,(%esp)
801057ac:	e8 10 c7 ff ff       	call   80101ec1 <writei>
801057b1:	83 f8 10             	cmp    $0x10,%eax
801057b4:	74 0c                	je     801057c2 <sys_unlink+0x154>
    panic("unlink: writei");
801057b6:	c7 04 24 8c 84 10 80 	movl   $0x8010848c,(%esp)
801057bd:	e8 7b ad ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR){
801057c2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801057c5:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801057c9:	66 83 f8 01          	cmp    $0x1,%ax
801057cd:	75 1c                	jne    801057eb <sys_unlink+0x17d>
    dp->nlink--;
801057cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057d2:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801057d6:	8d 50 ff             	lea    -0x1(%eax),%edx
801057d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057dc:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
801057e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057e3:	89 04 24             	mov    %eax,(%esp)
801057e6:	e8 b9 be ff ff       	call   801016a4 <iupdate>
  }
  iunlockput(dp);
801057eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057ee:	89 04 24             	mov    %eax,(%esp)
801057f1:	e8 ee c2 ff ff       	call   80101ae4 <iunlockput>

  ip->nlink--;
801057f6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801057f9:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801057fd:	8d 50 ff             	lea    -0x1(%eax),%edx
80105800:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105803:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80105807:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010580a:	89 04 24             	mov    %eax,(%esp)
8010580d:	e8 92 be ff ff       	call   801016a4 <iupdate>
  iunlockput(ip);
80105812:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105815:	89 04 24             	mov    %eax,(%esp)
80105818:	e8 c7 c2 ff ff       	call   80101ae4 <iunlockput>

  commit_trans();
8010581d:	e8 3c da ff ff       	call   8010325e <commit_trans>

  return 0;
80105822:	b8 00 00 00 00       	mov    $0x0,%eax
80105827:	eb 16                	jmp    8010583f <sys_unlink+0x1d1>
  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    goto bad;
80105829:	90                   	nop
  commit_trans();

  return 0;

bad:
  iunlockput(dp);
8010582a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010582d:	89 04 24             	mov    %eax,(%esp)
80105830:	e8 af c2 ff ff       	call   80101ae4 <iunlockput>
  commit_trans();
80105835:	e8 24 da ff ff       	call   8010325e <commit_trans>
  return -1;
8010583a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010583f:	c9                   	leave  
80105840:	c3                   	ret    

80105841 <create>:

static struct inode*
create(char *path, short type, short major, short minor)
{
80105841:	55                   	push   %ebp
80105842:	89 e5                	mov    %esp,%ebp
80105844:	83 ec 48             	sub    $0x48,%esp
80105847:	8b 4d 0c             	mov    0xc(%ebp),%ecx
8010584a:	8b 55 10             	mov    0x10(%ebp),%edx
8010584d:	8b 45 14             	mov    0x14(%ebp),%eax
80105850:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
80105854:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
80105858:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
8010585c:	8d 45 de             	lea    -0x22(%ebp),%eax
8010585f:	89 44 24 04          	mov    %eax,0x4(%esp)
80105863:	8b 45 08             	mov    0x8(%ebp),%eax
80105866:	89 04 24             	mov    %eax,(%esp)
80105869:	e8 b6 cb ff ff       	call   80102424 <nameiparent>
8010586e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105871:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105875:	75 0a                	jne    80105881 <create+0x40>
    return 0;
80105877:	b8 00 00 00 00       	mov    $0x0,%eax
8010587c:	e9 7e 01 00 00       	jmp    801059ff <create+0x1be>
  ilock(dp);
80105881:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105884:	89 04 24             	mov    %eax,(%esp)
80105887:	e8 d4 bf ff ff       	call   80101860 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
8010588c:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010588f:	89 44 24 08          	mov    %eax,0x8(%esp)
80105893:	8d 45 de             	lea    -0x22(%ebp),%eax
80105896:	89 44 24 04          	mov    %eax,0x4(%esp)
8010589a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010589d:	89 04 24             	mov    %eax,(%esp)
801058a0:	e8 d4 c7 ff ff       	call   80102079 <dirlookup>
801058a5:	89 45 f0             	mov    %eax,-0x10(%ebp)
801058a8:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801058ac:	74 47                	je     801058f5 <create+0xb4>
    iunlockput(dp);
801058ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058b1:	89 04 24             	mov    %eax,(%esp)
801058b4:	e8 2b c2 ff ff       	call   80101ae4 <iunlockput>
    ilock(ip);
801058b9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801058bc:	89 04 24             	mov    %eax,(%esp)
801058bf:	e8 9c bf ff ff       	call   80101860 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
801058c4:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
801058c9:	75 15                	jne    801058e0 <create+0x9f>
801058cb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801058ce:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801058d2:	66 83 f8 02          	cmp    $0x2,%ax
801058d6:	75 08                	jne    801058e0 <create+0x9f>
      return ip;
801058d8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801058db:	e9 1f 01 00 00       	jmp    801059ff <create+0x1be>
    iunlockput(ip);
801058e0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801058e3:	89 04 24             	mov    %eax,(%esp)
801058e6:	e8 f9 c1 ff ff       	call   80101ae4 <iunlockput>
    return 0;
801058eb:	b8 00 00 00 00       	mov    $0x0,%eax
801058f0:	e9 0a 01 00 00       	jmp    801059ff <create+0x1be>
  }

  if((ip = ialloc(dp->dev, type)) == 0)
801058f5:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
801058f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058fc:	8b 00                	mov    (%eax),%eax
801058fe:	89 54 24 04          	mov    %edx,0x4(%esp)
80105902:	89 04 24             	mov    %eax,(%esp)
80105905:	e8 bd bc ff ff       	call   801015c7 <ialloc>
8010590a:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010590d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105911:	75 0c                	jne    8010591f <create+0xde>
    panic("create: ialloc");
80105913:	c7 04 24 9b 84 10 80 	movl   $0x8010849b,(%esp)
8010591a:	e8 1e ac ff ff       	call   8010053d <panic>

  ilock(ip);
8010591f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105922:	89 04 24             	mov    %eax,(%esp)
80105925:	e8 36 bf ff ff       	call   80101860 <ilock>
  ip->major = major;
8010592a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010592d:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
80105931:	66 89 50 12          	mov    %dx,0x12(%eax)
  ip->minor = minor;
80105935:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105938:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
8010593c:	66 89 50 14          	mov    %dx,0x14(%eax)
  ip->nlink = 1;
80105940:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105943:	66 c7 40 16 01 00    	movw   $0x1,0x16(%eax)
  iupdate(ip);
80105949:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010594c:	89 04 24             	mov    %eax,(%esp)
8010594f:	e8 50 bd ff ff       	call   801016a4 <iupdate>

  if(type == T_DIR){  // Create . and .. entries.
80105954:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
80105959:	75 6a                	jne    801059c5 <create+0x184>
    dp->nlink++;  // for ".."
8010595b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010595e:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105962:	8d 50 01             	lea    0x1(%eax),%edx
80105965:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105968:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
8010596c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010596f:	89 04 24             	mov    %eax,(%esp)
80105972:	e8 2d bd ff ff       	call   801016a4 <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80105977:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010597a:	8b 40 04             	mov    0x4(%eax),%eax
8010597d:	89 44 24 08          	mov    %eax,0x8(%esp)
80105981:	c7 44 24 04 75 84 10 	movl   $0x80108475,0x4(%esp)
80105988:	80 
80105989:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010598c:	89 04 24             	mov    %eax,(%esp)
8010598f:	e8 ad c7 ff ff       	call   80102141 <dirlink>
80105994:	85 c0                	test   %eax,%eax
80105996:	78 21                	js     801059b9 <create+0x178>
80105998:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010599b:	8b 40 04             	mov    0x4(%eax),%eax
8010599e:	89 44 24 08          	mov    %eax,0x8(%esp)
801059a2:	c7 44 24 04 77 84 10 	movl   $0x80108477,0x4(%esp)
801059a9:	80 
801059aa:	8b 45 f0             	mov    -0x10(%ebp),%eax
801059ad:	89 04 24             	mov    %eax,(%esp)
801059b0:	e8 8c c7 ff ff       	call   80102141 <dirlink>
801059b5:	85 c0                	test   %eax,%eax
801059b7:	79 0c                	jns    801059c5 <create+0x184>
      panic("create dots");
801059b9:	c7 04 24 aa 84 10 80 	movl   $0x801084aa,(%esp)
801059c0:	e8 78 ab ff ff       	call   8010053d <panic>
  }

  if(dirlink(dp, name, ip->inum) < 0)
801059c5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801059c8:	8b 40 04             	mov    0x4(%eax),%eax
801059cb:	89 44 24 08          	mov    %eax,0x8(%esp)
801059cf:	8d 45 de             	lea    -0x22(%ebp),%eax
801059d2:	89 44 24 04          	mov    %eax,0x4(%esp)
801059d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059d9:	89 04 24             	mov    %eax,(%esp)
801059dc:	e8 60 c7 ff ff       	call   80102141 <dirlink>
801059e1:	85 c0                	test   %eax,%eax
801059e3:	79 0c                	jns    801059f1 <create+0x1b0>
    panic("create: dirlink");
801059e5:	c7 04 24 b6 84 10 80 	movl   $0x801084b6,(%esp)
801059ec:	e8 4c ab ff ff       	call   8010053d <panic>

  iunlockput(dp);
801059f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059f4:	89 04 24             	mov    %eax,(%esp)
801059f7:	e8 e8 c0 ff ff       	call   80101ae4 <iunlockput>

  return ip;
801059fc:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
801059ff:	c9                   	leave  
80105a00:	c3                   	ret    

80105a01 <sys_open>:

int
sys_open(void)
{
80105a01:	55                   	push   %ebp
80105a02:	89 e5                	mov    %esp,%ebp
80105a04:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80105a07:	8d 45 e8             	lea    -0x18(%ebp),%eax
80105a0a:	89 44 24 04          	mov    %eax,0x4(%esp)
80105a0e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105a15:	e8 e4 f6 ff ff       	call   801050fe <argstr>
80105a1a:	85 c0                	test   %eax,%eax
80105a1c:	78 17                	js     80105a35 <sys_open+0x34>
80105a1e:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105a21:	89 44 24 04          	mov    %eax,0x4(%esp)
80105a25:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105a2c:	e8 3d f6 ff ff       	call   8010506e <argint>
80105a31:	85 c0                	test   %eax,%eax
80105a33:	79 0a                	jns    80105a3f <sys_open+0x3e>
    return -1;
80105a35:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105a3a:	e9 46 01 00 00       	jmp    80105b85 <sys_open+0x184>
  if(omode & O_CREATE){
80105a3f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105a42:	25 00 02 00 00       	and    $0x200,%eax
80105a47:	85 c0                	test   %eax,%eax
80105a49:	74 40                	je     80105a8b <sys_open+0x8a>
    begin_trans();
80105a4b:	e8 c5 d7 ff ff       	call   80103215 <begin_trans>
    ip = create(path, T_FILE, 0, 0);
80105a50:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105a53:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80105a5a:	00 
80105a5b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80105a62:	00 
80105a63:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80105a6a:	00 
80105a6b:	89 04 24             	mov    %eax,(%esp)
80105a6e:	e8 ce fd ff ff       	call   80105841 <create>
80105a73:	89 45 f4             	mov    %eax,-0xc(%ebp)
    commit_trans();
80105a76:	e8 e3 d7 ff ff       	call   8010325e <commit_trans>
    if(ip == 0)
80105a7b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105a7f:	75 5c                	jne    80105add <sys_open+0xdc>
      return -1;
80105a81:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105a86:	e9 fa 00 00 00       	jmp    80105b85 <sys_open+0x184>
  } else {
    if((ip = namei(path)) == 0)
80105a8b:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105a8e:	89 04 24             	mov    %eax,(%esp)
80105a91:	e8 6c c9 ff ff       	call   80102402 <namei>
80105a96:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105a99:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105a9d:	75 0a                	jne    80105aa9 <sys_open+0xa8>
      return -1;
80105a9f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105aa4:	e9 dc 00 00 00       	jmp    80105b85 <sys_open+0x184>
    ilock(ip);
80105aa9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105aac:	89 04 24             	mov    %eax,(%esp)
80105aaf:	e8 ac bd ff ff       	call   80101860 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80105ab4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ab7:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105abb:	66 83 f8 01          	cmp    $0x1,%ax
80105abf:	75 1c                	jne    80105add <sys_open+0xdc>
80105ac1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105ac4:	85 c0                	test   %eax,%eax
80105ac6:	74 15                	je     80105add <sys_open+0xdc>
      iunlockput(ip);
80105ac8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105acb:	89 04 24             	mov    %eax,(%esp)
80105ace:	e8 11 c0 ff ff       	call   80101ae4 <iunlockput>
      return -1;
80105ad3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105ad8:	e9 a8 00 00 00       	jmp    80105b85 <sys_open+0x184>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80105add:	e8 32 b4 ff ff       	call   80100f14 <filealloc>
80105ae2:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105ae5:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105ae9:	74 14                	je     80105aff <sys_open+0xfe>
80105aeb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105aee:	89 04 24             	mov    %eax,(%esp)
80105af1:	e8 43 f7 ff ff       	call   80105239 <fdalloc>
80105af6:	89 45 ec             	mov    %eax,-0x14(%ebp)
80105af9:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80105afd:	79 23                	jns    80105b22 <sys_open+0x121>
    if(f)
80105aff:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105b03:	74 0b                	je     80105b10 <sys_open+0x10f>
      fileclose(f);
80105b05:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b08:	89 04 24             	mov    %eax,(%esp)
80105b0b:	e8 ac b4 ff ff       	call   80100fbc <fileclose>
    iunlockput(ip);
80105b10:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b13:	89 04 24             	mov    %eax,(%esp)
80105b16:	e8 c9 bf ff ff       	call   80101ae4 <iunlockput>
    return -1;
80105b1b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105b20:	eb 63                	jmp    80105b85 <sys_open+0x184>
  }
  iunlock(ip);
80105b22:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b25:	89 04 24             	mov    %eax,(%esp)
80105b28:	e8 81 be ff ff       	call   801019ae <iunlock>

  f->type = FD_INODE;
80105b2d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b30:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80105b36:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b39:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105b3c:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
80105b3f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b42:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80105b49:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105b4c:	83 e0 01             	and    $0x1,%eax
80105b4f:	85 c0                	test   %eax,%eax
80105b51:	0f 94 c2             	sete   %dl
80105b54:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b57:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80105b5a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105b5d:	83 e0 01             	and    $0x1,%eax
80105b60:	84 c0                	test   %al,%al
80105b62:	75 0a                	jne    80105b6e <sys_open+0x16d>
80105b64:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105b67:	83 e0 02             	and    $0x2,%eax
80105b6a:	85 c0                	test   %eax,%eax
80105b6c:	74 07                	je     80105b75 <sys_open+0x174>
80105b6e:	b8 01 00 00 00       	mov    $0x1,%eax
80105b73:	eb 05                	jmp    80105b7a <sys_open+0x179>
80105b75:	b8 00 00 00 00       	mov    $0x0,%eax
80105b7a:	89 c2                	mov    %eax,%edx
80105b7c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b7f:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
80105b82:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
80105b85:	c9                   	leave  
80105b86:	c3                   	ret    

80105b87 <sys_mkdir>:

int
sys_mkdir(void)
{
80105b87:	55                   	push   %ebp
80105b88:	89 e5                	mov    %esp,%ebp
80105b8a:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_trans();
80105b8d:	e8 83 d6 ff ff       	call   80103215 <begin_trans>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80105b92:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105b95:	89 44 24 04          	mov    %eax,0x4(%esp)
80105b99:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105ba0:	e8 59 f5 ff ff       	call   801050fe <argstr>
80105ba5:	85 c0                	test   %eax,%eax
80105ba7:	78 2c                	js     80105bd5 <sys_mkdir+0x4e>
80105ba9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105bac:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80105bb3:	00 
80105bb4:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80105bbb:	00 
80105bbc:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80105bc3:	00 
80105bc4:	89 04 24             	mov    %eax,(%esp)
80105bc7:	e8 75 fc ff ff       	call   80105841 <create>
80105bcc:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105bcf:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105bd3:	75 0c                	jne    80105be1 <sys_mkdir+0x5a>
    commit_trans();
80105bd5:	e8 84 d6 ff ff       	call   8010325e <commit_trans>
    return -1;
80105bda:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105bdf:	eb 15                	jmp    80105bf6 <sys_mkdir+0x6f>
  }
  iunlockput(ip);
80105be1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105be4:	89 04 24             	mov    %eax,(%esp)
80105be7:	e8 f8 be ff ff       	call   80101ae4 <iunlockput>
  commit_trans();
80105bec:	e8 6d d6 ff ff       	call   8010325e <commit_trans>
  return 0;
80105bf1:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105bf6:	c9                   	leave  
80105bf7:	c3                   	ret    

80105bf8 <sys_mknod>:

int
sys_mknod(void)
{
80105bf8:	55                   	push   %ebp
80105bf9:	89 e5                	mov    %esp,%ebp
80105bfb:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
80105bfe:	e8 12 d6 ff ff       	call   80103215 <begin_trans>
  if((len=argstr(0, &path)) < 0 ||
80105c03:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105c06:	89 44 24 04          	mov    %eax,0x4(%esp)
80105c0a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105c11:	e8 e8 f4 ff ff       	call   801050fe <argstr>
80105c16:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105c19:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105c1d:	78 5e                	js     80105c7d <sys_mknod+0x85>
     argint(1, &major) < 0 ||
80105c1f:	8d 45 e8             	lea    -0x18(%ebp),%eax
80105c22:	89 44 24 04          	mov    %eax,0x4(%esp)
80105c26:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105c2d:	e8 3c f4 ff ff       	call   8010506e <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
80105c32:	85 c0                	test   %eax,%eax
80105c34:	78 47                	js     80105c7d <sys_mknod+0x85>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80105c36:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105c39:	89 44 24 04          	mov    %eax,0x4(%esp)
80105c3d:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80105c44:	e8 25 f4 ff ff       	call   8010506e <argint>
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
80105c49:	85 c0                	test   %eax,%eax
80105c4b:	78 30                	js     80105c7d <sys_mknod+0x85>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
80105c4d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105c50:	0f bf c8             	movswl %ax,%ecx
80105c53:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105c56:	0f bf d0             	movswl %ax,%edx
80105c59:	8b 45 ec             	mov    -0x14(%ebp),%eax
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80105c5c:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80105c60:	89 54 24 08          	mov    %edx,0x8(%esp)
80105c64:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80105c6b:	00 
80105c6c:	89 04 24             	mov    %eax,(%esp)
80105c6f:	e8 cd fb ff ff       	call   80105841 <create>
80105c74:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105c77:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105c7b:	75 0c                	jne    80105c89 <sys_mknod+0x91>
     (ip = create(path, T_DEV, major, minor)) == 0){
    commit_trans();
80105c7d:	e8 dc d5 ff ff       	call   8010325e <commit_trans>
    return -1;
80105c82:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105c87:	eb 15                	jmp    80105c9e <sys_mknod+0xa6>
  }
  iunlockput(ip);
80105c89:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c8c:	89 04 24             	mov    %eax,(%esp)
80105c8f:	e8 50 be ff ff       	call   80101ae4 <iunlockput>
  commit_trans();
80105c94:	e8 c5 d5 ff ff       	call   8010325e <commit_trans>
  return 0;
80105c99:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105c9e:	c9                   	leave  
80105c9f:	c3                   	ret    

80105ca0 <sys_chdir>:

int
sys_chdir(void)
{
80105ca0:	55                   	push   %ebp
80105ca1:	89 e5                	mov    %esp,%ebp
80105ca3:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0)
80105ca6:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105ca9:	89 44 24 04          	mov    %eax,0x4(%esp)
80105cad:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105cb4:	e8 45 f4 ff ff       	call   801050fe <argstr>
80105cb9:	85 c0                	test   %eax,%eax
80105cbb:	78 14                	js     80105cd1 <sys_chdir+0x31>
80105cbd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105cc0:	89 04 24             	mov    %eax,(%esp)
80105cc3:	e8 3a c7 ff ff       	call   80102402 <namei>
80105cc8:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105ccb:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105ccf:	75 07                	jne    80105cd8 <sys_chdir+0x38>
    return -1;
80105cd1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105cd6:	eb 57                	jmp    80105d2f <sys_chdir+0x8f>
  ilock(ip);
80105cd8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105cdb:	89 04 24             	mov    %eax,(%esp)
80105cde:	e8 7d bb ff ff       	call   80101860 <ilock>
  if(ip->type != T_DIR){
80105ce3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ce6:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105cea:	66 83 f8 01          	cmp    $0x1,%ax
80105cee:	74 12                	je     80105d02 <sys_chdir+0x62>
    iunlockput(ip);
80105cf0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105cf3:	89 04 24             	mov    %eax,(%esp)
80105cf6:	e8 e9 bd ff ff       	call   80101ae4 <iunlockput>
    return -1;
80105cfb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105d00:	eb 2d                	jmp    80105d2f <sys_chdir+0x8f>
  }
  iunlock(ip);
80105d02:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d05:	89 04 24             	mov    %eax,(%esp)
80105d08:	e8 a1 bc ff ff       	call   801019ae <iunlock>
  iput(proc->cwd);
80105d0d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105d13:	8b 40 68             	mov    0x68(%eax),%eax
80105d16:	89 04 24             	mov    %eax,(%esp)
80105d19:	e8 f5 bc ff ff       	call   80101a13 <iput>
  proc->cwd = ip;
80105d1e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105d24:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105d27:	89 50 68             	mov    %edx,0x68(%eax)
  return 0;
80105d2a:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105d2f:	c9                   	leave  
80105d30:	c3                   	ret    

80105d31 <sys_exec>:

int
sys_exec(void)
{
80105d31:	55                   	push   %ebp
80105d32:	89 e5                	mov    %esp,%ebp
80105d34:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80105d3a:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105d3d:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d41:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105d48:	e8 b1 f3 ff ff       	call   801050fe <argstr>
80105d4d:	85 c0                	test   %eax,%eax
80105d4f:	78 1a                	js     80105d6b <sys_exec+0x3a>
80105d51:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80105d57:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d5b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105d62:	e8 07 f3 ff ff       	call   8010506e <argint>
80105d67:	85 c0                	test   %eax,%eax
80105d69:	79 0a                	jns    80105d75 <sys_exec+0x44>
    return -1;
80105d6b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105d70:	e9 cc 00 00 00       	jmp    80105e41 <sys_exec+0x110>
  }
  memset(argv, 0, sizeof(argv));
80105d75:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80105d7c:	00 
80105d7d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105d84:	00 
80105d85:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80105d8b:	89 04 24             	mov    %eax,(%esp)
80105d8e:	e8 7f ef ff ff       	call   80104d12 <memset>
  for(i=0;; i++){
80105d93:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
80105d9a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d9d:	83 f8 1f             	cmp    $0x1f,%eax
80105da0:	76 0a                	jbe    80105dac <sys_exec+0x7b>
      return -1;
80105da2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105da7:	e9 95 00 00 00       	jmp    80105e41 <sys_exec+0x110>
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80105dac:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105daf:	c1 e0 02             	shl    $0x2,%eax
80105db2:	89 c2                	mov    %eax,%edx
80105db4:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80105dba:	01 c2                	add    %eax,%edx
80105dbc:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
80105dc2:	89 44 24 04          	mov    %eax,0x4(%esp)
80105dc6:	89 14 24             	mov    %edx,(%esp)
80105dc9:	e8 02 f2 ff ff       	call   80104fd0 <fetchint>
80105dce:	85 c0                	test   %eax,%eax
80105dd0:	79 07                	jns    80105dd9 <sys_exec+0xa8>
      return -1;
80105dd2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105dd7:	eb 68                	jmp    80105e41 <sys_exec+0x110>
    if(uarg == 0){
80105dd9:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80105ddf:	85 c0                	test   %eax,%eax
80105de1:	75 26                	jne    80105e09 <sys_exec+0xd8>
      argv[i] = 0;
80105de3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105de6:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
80105ded:	00 00 00 00 
      break;
80105df1:	90                   	nop
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
80105df2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105df5:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
80105dfb:	89 54 24 04          	mov    %edx,0x4(%esp)
80105dff:	89 04 24             	mov    %eax,(%esp)
80105e02:	e8 f5 ac ff ff       	call   80100afc <exec>
80105e07:	eb 38                	jmp    80105e41 <sys_exec+0x110>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
80105e09:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e0c:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80105e13:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80105e19:	01 c2                	add    %eax,%edx
80105e1b:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80105e21:	89 54 24 04          	mov    %edx,0x4(%esp)
80105e25:	89 04 24             	mov    %eax,(%esp)
80105e28:	e8 dd f1 ff ff       	call   8010500a <fetchstr>
80105e2d:	85 c0                	test   %eax,%eax
80105e2f:	79 07                	jns    80105e38 <sys_exec+0x107>
      return -1;
80105e31:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105e36:	eb 09                	jmp    80105e41 <sys_exec+0x110>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
80105e38:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
80105e3c:	e9 59 ff ff ff       	jmp    80105d9a <sys_exec+0x69>
  return exec(path, argv);
}
80105e41:	c9                   	leave  
80105e42:	c3                   	ret    

80105e43 <sys_pipe>:

int
sys_pipe(void)
{
80105e43:	55                   	push   %ebp
80105e44:	89 e5                	mov    %esp,%ebp
80105e46:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80105e49:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
80105e50:	00 
80105e51:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105e54:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e58:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105e5f:	e8 38 f2 ff ff       	call   8010509c <argptr>
80105e64:	85 c0                	test   %eax,%eax
80105e66:	79 0a                	jns    80105e72 <sys_pipe+0x2f>
    return -1;
80105e68:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105e6d:	e9 9b 00 00 00       	jmp    80105f0d <sys_pipe+0xca>
  if(pipealloc(&rf, &wf) < 0)
80105e72:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105e75:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e79:	8d 45 e8             	lea    -0x18(%ebp),%eax
80105e7c:	89 04 24             	mov    %eax,(%esp)
80105e7f:	e8 9c dd ff ff       	call   80103c20 <pipealloc>
80105e84:	85 c0                	test   %eax,%eax
80105e86:	79 07                	jns    80105e8f <sys_pipe+0x4c>
    return -1;
80105e88:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105e8d:	eb 7e                	jmp    80105f0d <sys_pipe+0xca>
  fd0 = -1;
80105e8f:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80105e96:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105e99:	89 04 24             	mov    %eax,(%esp)
80105e9c:	e8 98 f3 ff ff       	call   80105239 <fdalloc>
80105ea1:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105ea4:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105ea8:	78 14                	js     80105ebe <sys_pipe+0x7b>
80105eaa:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105ead:	89 04 24             	mov    %eax,(%esp)
80105eb0:	e8 84 f3 ff ff       	call   80105239 <fdalloc>
80105eb5:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105eb8:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105ebc:	79 37                	jns    80105ef5 <sys_pipe+0xb2>
    if(fd0 >= 0)
80105ebe:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105ec2:	78 14                	js     80105ed8 <sys_pipe+0x95>
      proc->ofile[fd0] = 0;
80105ec4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105eca:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105ecd:	83 c2 08             	add    $0x8,%edx
80105ed0:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80105ed7:	00 
    fileclose(rf);
80105ed8:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105edb:	89 04 24             	mov    %eax,(%esp)
80105ede:	e8 d9 b0 ff ff       	call   80100fbc <fileclose>
    fileclose(wf);
80105ee3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105ee6:	89 04 24             	mov    %eax,(%esp)
80105ee9:	e8 ce b0 ff ff       	call   80100fbc <fileclose>
    return -1;
80105eee:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105ef3:	eb 18                	jmp    80105f0d <sys_pipe+0xca>
  }
  fd[0] = fd0;
80105ef5:	8b 45 ec             	mov    -0x14(%ebp),%eax
80105ef8:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105efb:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
80105efd:	8b 45 ec             	mov    -0x14(%ebp),%eax
80105f00:	8d 50 04             	lea    0x4(%eax),%edx
80105f03:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f06:	89 02                	mov    %eax,(%edx)
  return 0;
80105f08:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105f0d:	c9                   	leave  
80105f0e:	c3                   	ret    
	...

80105f10 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80105f10:	55                   	push   %ebp
80105f11:	89 e5                	mov    %esp,%ebp
80105f13:	83 ec 08             	sub    $0x8,%esp
  return fork();
80105f16:	e8 99 e3 ff ff       	call   801042b4 <fork>
}
80105f1b:	c9                   	leave  
80105f1c:	c3                   	ret    

80105f1d <sys_exit>:

int
sys_exit(void)
{
80105f1d:	55                   	push   %ebp
80105f1e:	89 e5                	mov    %esp,%ebp
80105f20:	83 ec 08             	sub    $0x8,%esp
  exit();
80105f23:	e8 ef e4 ff ff       	call   80104417 <exit>
  return 0;  // not reached
80105f28:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105f2d:	c9                   	leave  
80105f2e:	c3                   	ret    

80105f2f <sys_wait>:

int
sys_wait(void)
{
80105f2f:	55                   	push   %ebp
80105f30:	89 e5                	mov    %esp,%ebp
80105f32:	83 ec 08             	sub    $0x8,%esp
  return wait();
80105f35:	e8 f5 e5 ff ff       	call   8010452f <wait>
}
80105f3a:	c9                   	leave  
80105f3b:	c3                   	ret    

80105f3c <sys_kill>:

int
sys_kill(void)
{
80105f3c:	55                   	push   %ebp
80105f3d:	89 e5                	mov    %esp,%ebp
80105f3f:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
80105f42:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105f45:	89 44 24 04          	mov    %eax,0x4(%esp)
80105f49:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105f50:	e8 19 f1 ff ff       	call   8010506e <argint>
80105f55:	85 c0                	test   %eax,%eax
80105f57:	79 07                	jns    80105f60 <sys_kill+0x24>
    return -1;
80105f59:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f5e:	eb 0b                	jmp    80105f6b <sys_kill+0x2f>
  return kill(pid);
80105f60:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f63:	89 04 24             	mov    %eax,(%esp)
80105f66:	e8 80 e9 ff ff       	call   801048eb <kill>
}
80105f6b:	c9                   	leave  
80105f6c:	c3                   	ret    

80105f6d <sys_getpid>:

int
sys_getpid(void)
{
80105f6d:	55                   	push   %ebp
80105f6e:	89 e5                	mov    %esp,%ebp
  return proc->pid;
80105f70:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105f76:	8b 40 10             	mov    0x10(%eax),%eax
}
80105f79:	5d                   	pop    %ebp
80105f7a:	c3                   	ret    

80105f7b <sys_sbrk>:

int
sys_sbrk(void)
{
80105f7b:	55                   	push   %ebp
80105f7c:	89 e5                	mov    %esp,%ebp
80105f7e:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80105f81:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105f84:	89 44 24 04          	mov    %eax,0x4(%esp)
80105f88:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105f8f:	e8 da f0 ff ff       	call   8010506e <argint>
80105f94:	85 c0                	test   %eax,%eax
80105f96:	79 07                	jns    80105f9f <sys_sbrk+0x24>
    return -1;
80105f98:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f9d:	eb 24                	jmp    80105fc3 <sys_sbrk+0x48>
  addr = proc->sz;
80105f9f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105fa5:	8b 00                	mov    (%eax),%eax
80105fa7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
80105faa:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105fad:	89 04 24             	mov    %eax,(%esp)
80105fb0:	e8 5a e2 ff ff       	call   8010420f <growproc>
80105fb5:	85 c0                	test   %eax,%eax
80105fb7:	79 07                	jns    80105fc0 <sys_sbrk+0x45>
    return -1;
80105fb9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105fbe:	eb 03                	jmp    80105fc3 <sys_sbrk+0x48>
  return addr;
80105fc0:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80105fc3:	c9                   	leave  
80105fc4:	c3                   	ret    

80105fc5 <sys_sleep>:

int
sys_sleep(void)
{
80105fc5:	55                   	push   %ebp
80105fc6:	89 e5                	mov    %esp,%ebp
80105fc8:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
80105fcb:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105fce:	89 44 24 04          	mov    %eax,0x4(%esp)
80105fd2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105fd9:	e8 90 f0 ff ff       	call   8010506e <argint>
80105fde:	85 c0                	test   %eax,%eax
80105fe0:	79 07                	jns    80105fe9 <sys_sleep+0x24>
    return -1;
80105fe2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105fe7:	eb 6c                	jmp    80106055 <sys_sleep+0x90>
  acquire(&tickslock);
80105fe9:	c7 04 24 60 1e 11 80 	movl   $0x80111e60,(%esp)
80105ff0:	e8 ce ea ff ff       	call   80104ac3 <acquire>
  ticks0 = ticks;
80105ff5:	a1 a0 26 11 80       	mov    0x801126a0,%eax
80105ffa:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
80105ffd:	eb 34                	jmp    80106033 <sys_sleep+0x6e>
    if(proc->killed){
80105fff:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106005:	8b 40 24             	mov    0x24(%eax),%eax
80106008:	85 c0                	test   %eax,%eax
8010600a:	74 13                	je     8010601f <sys_sleep+0x5a>
      release(&tickslock);
8010600c:	c7 04 24 60 1e 11 80 	movl   $0x80111e60,(%esp)
80106013:	e8 0d eb ff ff       	call   80104b25 <release>
      return -1;
80106018:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010601d:	eb 36                	jmp    80106055 <sys_sleep+0x90>
    }
    sleep(&ticks, &tickslock);
8010601f:	c7 44 24 04 60 1e 11 	movl   $0x80111e60,0x4(%esp)
80106026:	80 
80106027:	c7 04 24 a0 26 11 80 	movl   $0x801126a0,(%esp)
8010602e:	e8 b4 e7 ff ff       	call   801047e7 <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
80106033:	a1 a0 26 11 80       	mov    0x801126a0,%eax
80106038:	89 c2                	mov    %eax,%edx
8010603a:	2b 55 f4             	sub    -0xc(%ebp),%edx
8010603d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106040:	39 c2                	cmp    %eax,%edx
80106042:	72 bb                	jb     80105fff <sys_sleep+0x3a>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
80106044:	c7 04 24 60 1e 11 80 	movl   $0x80111e60,(%esp)
8010604b:	e8 d5 ea ff ff       	call   80104b25 <release>
  return 0;
80106050:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106055:	c9                   	leave  
80106056:	c3                   	ret    

80106057 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80106057:	55                   	push   %ebp
80106058:	89 e5                	mov    %esp,%ebp
8010605a:	83 ec 28             	sub    $0x28,%esp
  uint xticks;
  
  acquire(&tickslock);
8010605d:	c7 04 24 60 1e 11 80 	movl   $0x80111e60,(%esp)
80106064:	e8 5a ea ff ff       	call   80104ac3 <acquire>
  xticks = ticks;
80106069:	a1 a0 26 11 80       	mov    0x801126a0,%eax
8010606e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
80106071:	c7 04 24 60 1e 11 80 	movl   $0x80111e60,(%esp)
80106078:	e8 a8 ea ff ff       	call   80104b25 <release>
  return xticks;
8010607d:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80106080:	c9                   	leave  
80106081:	c3                   	ret    
	...

80106084 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80106084:	55                   	push   %ebp
80106085:	89 e5                	mov    %esp,%ebp
80106087:	83 ec 08             	sub    $0x8,%esp
8010608a:	8b 55 08             	mov    0x8(%ebp),%edx
8010608d:	8b 45 0c             	mov    0xc(%ebp),%eax
80106090:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80106094:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80106097:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
8010609b:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
8010609f:	ee                   	out    %al,(%dx)
}
801060a0:	c9                   	leave  
801060a1:	c3                   	ret    

801060a2 <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
801060a2:	55                   	push   %ebp
801060a3:	89 e5                	mov    %esp,%ebp
801060a5:	83 ec 18             	sub    $0x18,%esp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
801060a8:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
801060af:	00 
801060b0:	c7 04 24 43 00 00 00 	movl   $0x43,(%esp)
801060b7:	e8 c8 ff ff ff       	call   80106084 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
801060bc:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
801060c3:	00 
801060c4:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
801060cb:	e8 b4 ff ff ff       	call   80106084 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
801060d0:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
801060d7:	00 
801060d8:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
801060df:	e8 a0 ff ff ff       	call   80106084 <outb>
  picenable(IRQ_TIMER);
801060e4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801060eb:	e8 b9 d9 ff ff       	call   80103aa9 <picenable>
}
801060f0:	c9                   	leave  
801060f1:	c3                   	ret    
	...

801060f4 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
801060f4:	1e                   	push   %ds
  pushl %es
801060f5:	06                   	push   %es
  pushl %fs
801060f6:	0f a0                	push   %fs
  pushl %gs
801060f8:	0f a8                	push   %gs
  pushal
801060fa:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
801060fb:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
801060ff:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80106101:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
80106103:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
80106107:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
80106109:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
8010610b:	54                   	push   %esp
  call trap
8010610c:	e8 de 01 00 00       	call   801062ef <trap>
  addl $4, %esp
80106111:	83 c4 04             	add    $0x4,%esp

80106114 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80106114:	61                   	popa   
  popl %gs
80106115:	0f a9                	pop    %gs
  popl %fs
80106117:	0f a1                	pop    %fs
  popl %es
80106119:	07                   	pop    %es
  popl %ds
8010611a:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
8010611b:	83 c4 08             	add    $0x8,%esp
  iret
8010611e:	cf                   	iret   
	...

80106120 <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
80106120:	55                   	push   %ebp
80106121:	89 e5                	mov    %esp,%ebp
80106123:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80106126:	8b 45 0c             	mov    0xc(%ebp),%eax
80106129:	83 e8 01             	sub    $0x1,%eax
8010612c:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80106130:	8b 45 08             	mov    0x8(%ebp),%eax
80106133:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80106137:	8b 45 08             	mov    0x8(%ebp),%eax
8010613a:	c1 e8 10             	shr    $0x10,%eax
8010613d:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
80106141:	8d 45 fa             	lea    -0x6(%ebp),%eax
80106144:	0f 01 18             	lidtl  (%eax)
}
80106147:	c9                   	leave  
80106148:	c3                   	ret    

80106149 <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
80106149:	55                   	push   %ebp
8010614a:	89 e5                	mov    %esp,%ebp
8010614c:	53                   	push   %ebx
8010614d:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
80106150:	0f 20 d3             	mov    %cr2,%ebx
80106153:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return val;
80106156:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80106159:	83 c4 10             	add    $0x10,%esp
8010615c:	5b                   	pop    %ebx
8010615d:	5d                   	pop    %ebp
8010615e:	c3                   	ret    

8010615f <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
8010615f:	55                   	push   %ebp
80106160:	89 e5                	mov    %esp,%ebp
80106162:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
80106165:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010616c:	e9 c3 00 00 00       	jmp    80106234 <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80106171:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106174:	8b 04 85 98 b0 10 80 	mov    -0x7fef4f68(,%eax,4),%eax
8010617b:	89 c2                	mov    %eax,%edx
8010617d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106180:	66 89 14 c5 a0 1e 11 	mov    %dx,-0x7feee160(,%eax,8)
80106187:	80 
80106188:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010618b:	66 c7 04 c5 a2 1e 11 	movw   $0x8,-0x7feee15e(,%eax,8)
80106192:	80 08 00 
80106195:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106198:	0f b6 14 c5 a4 1e 11 	movzbl -0x7feee15c(,%eax,8),%edx
8010619f:	80 
801061a0:	83 e2 e0             	and    $0xffffffe0,%edx
801061a3:	88 14 c5 a4 1e 11 80 	mov    %dl,-0x7feee15c(,%eax,8)
801061aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061ad:	0f b6 14 c5 a4 1e 11 	movzbl -0x7feee15c(,%eax,8),%edx
801061b4:	80 
801061b5:	83 e2 1f             	and    $0x1f,%edx
801061b8:	88 14 c5 a4 1e 11 80 	mov    %dl,-0x7feee15c(,%eax,8)
801061bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061c2:	0f b6 14 c5 a5 1e 11 	movzbl -0x7feee15b(,%eax,8),%edx
801061c9:	80 
801061ca:	83 e2 f0             	and    $0xfffffff0,%edx
801061cd:	83 ca 0e             	or     $0xe,%edx
801061d0:	88 14 c5 a5 1e 11 80 	mov    %dl,-0x7feee15b(,%eax,8)
801061d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061da:	0f b6 14 c5 a5 1e 11 	movzbl -0x7feee15b(,%eax,8),%edx
801061e1:	80 
801061e2:	83 e2 ef             	and    $0xffffffef,%edx
801061e5:	88 14 c5 a5 1e 11 80 	mov    %dl,-0x7feee15b(,%eax,8)
801061ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061ef:	0f b6 14 c5 a5 1e 11 	movzbl -0x7feee15b(,%eax,8),%edx
801061f6:	80 
801061f7:	83 e2 9f             	and    $0xffffff9f,%edx
801061fa:	88 14 c5 a5 1e 11 80 	mov    %dl,-0x7feee15b(,%eax,8)
80106201:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106204:	0f b6 14 c5 a5 1e 11 	movzbl -0x7feee15b(,%eax,8),%edx
8010620b:	80 
8010620c:	83 ca 80             	or     $0xffffff80,%edx
8010620f:	88 14 c5 a5 1e 11 80 	mov    %dl,-0x7feee15b(,%eax,8)
80106216:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106219:	8b 04 85 98 b0 10 80 	mov    -0x7fef4f68(,%eax,4),%eax
80106220:	c1 e8 10             	shr    $0x10,%eax
80106223:	89 c2                	mov    %eax,%edx
80106225:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106228:	66 89 14 c5 a6 1e 11 	mov    %dx,-0x7feee15a(,%eax,8)
8010622f:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
80106230:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106234:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
8010623b:	0f 8e 30 ff ff ff    	jle    80106171 <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80106241:	a1 98 b1 10 80       	mov    0x8010b198,%eax
80106246:	66 a3 a0 20 11 80    	mov    %ax,0x801120a0
8010624c:	66 c7 05 a2 20 11 80 	movw   $0x8,0x801120a2
80106253:	08 00 
80106255:	0f b6 05 a4 20 11 80 	movzbl 0x801120a4,%eax
8010625c:	83 e0 e0             	and    $0xffffffe0,%eax
8010625f:	a2 a4 20 11 80       	mov    %al,0x801120a4
80106264:	0f b6 05 a4 20 11 80 	movzbl 0x801120a4,%eax
8010626b:	83 e0 1f             	and    $0x1f,%eax
8010626e:	a2 a4 20 11 80       	mov    %al,0x801120a4
80106273:	0f b6 05 a5 20 11 80 	movzbl 0x801120a5,%eax
8010627a:	83 c8 0f             	or     $0xf,%eax
8010627d:	a2 a5 20 11 80       	mov    %al,0x801120a5
80106282:	0f b6 05 a5 20 11 80 	movzbl 0x801120a5,%eax
80106289:	83 e0 ef             	and    $0xffffffef,%eax
8010628c:	a2 a5 20 11 80       	mov    %al,0x801120a5
80106291:	0f b6 05 a5 20 11 80 	movzbl 0x801120a5,%eax
80106298:	83 c8 60             	or     $0x60,%eax
8010629b:	a2 a5 20 11 80       	mov    %al,0x801120a5
801062a0:	0f b6 05 a5 20 11 80 	movzbl 0x801120a5,%eax
801062a7:	83 c8 80             	or     $0xffffff80,%eax
801062aa:	a2 a5 20 11 80       	mov    %al,0x801120a5
801062af:	a1 98 b1 10 80       	mov    0x8010b198,%eax
801062b4:	c1 e8 10             	shr    $0x10,%eax
801062b7:	66 a3 a6 20 11 80    	mov    %ax,0x801120a6
  
  initlock(&tickslock, "time");
801062bd:	c7 44 24 04 c8 84 10 	movl   $0x801084c8,0x4(%esp)
801062c4:	80 
801062c5:	c7 04 24 60 1e 11 80 	movl   $0x80111e60,(%esp)
801062cc:	e8 d1 e7 ff ff       	call   80104aa2 <initlock>
}
801062d1:	c9                   	leave  
801062d2:	c3                   	ret    

801062d3 <idtinit>:

void
idtinit(void)
{
801062d3:	55                   	push   %ebp
801062d4:	89 e5                	mov    %esp,%ebp
801062d6:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
801062d9:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
801062e0:	00 
801062e1:	c7 04 24 a0 1e 11 80 	movl   $0x80111ea0,(%esp)
801062e8:	e8 33 fe ff ff       	call   80106120 <lidt>
}
801062ed:	c9                   	leave  
801062ee:	c3                   	ret    

801062ef <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
801062ef:	55                   	push   %ebp
801062f0:	89 e5                	mov    %esp,%ebp
801062f2:	57                   	push   %edi
801062f3:	56                   	push   %esi
801062f4:	53                   	push   %ebx
801062f5:	83 ec 3c             	sub    $0x3c,%esp
  if(tf->trapno == T_SYSCALL){
801062f8:	8b 45 08             	mov    0x8(%ebp),%eax
801062fb:	8b 40 30             	mov    0x30(%eax),%eax
801062fe:	83 f8 40             	cmp    $0x40,%eax
80106301:	75 3e                	jne    80106341 <trap+0x52>
    if(proc->killed)
80106303:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106309:	8b 40 24             	mov    0x24(%eax),%eax
8010630c:	85 c0                	test   %eax,%eax
8010630e:	74 05                	je     80106315 <trap+0x26>
      exit();
80106310:	e8 02 e1 ff ff       	call   80104417 <exit>
    proc->tf = tf;
80106315:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010631b:	8b 55 08             	mov    0x8(%ebp),%edx
8010631e:	89 50 18             	mov    %edx,0x18(%eax)
    syscall();
80106321:	e8 0f ee ff ff       	call   80105135 <syscall>
    if(proc->killed)
80106326:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010632c:	8b 40 24             	mov    0x24(%eax),%eax
8010632f:	85 c0                	test   %eax,%eax
80106331:	0f 84 34 02 00 00    	je     8010656b <trap+0x27c>
      exit();
80106337:	e8 db e0 ff ff       	call   80104417 <exit>
    return;
8010633c:	e9 2a 02 00 00       	jmp    8010656b <trap+0x27c>
  }

  switch(tf->trapno){
80106341:	8b 45 08             	mov    0x8(%ebp),%eax
80106344:	8b 40 30             	mov    0x30(%eax),%eax
80106347:	83 e8 20             	sub    $0x20,%eax
8010634a:	83 f8 1f             	cmp    $0x1f,%eax
8010634d:	0f 87 bc 00 00 00    	ja     8010640f <trap+0x120>
80106353:	8b 04 85 70 85 10 80 	mov    -0x7fef7a90(,%eax,4),%eax
8010635a:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
8010635c:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80106362:	0f b6 00             	movzbl (%eax),%eax
80106365:	84 c0                	test   %al,%al
80106367:	75 31                	jne    8010639a <trap+0xab>
      acquire(&tickslock);
80106369:	c7 04 24 60 1e 11 80 	movl   $0x80111e60,(%esp)
80106370:	e8 4e e7 ff ff       	call   80104ac3 <acquire>
      ticks++;
80106375:	a1 a0 26 11 80       	mov    0x801126a0,%eax
8010637a:	83 c0 01             	add    $0x1,%eax
8010637d:	a3 a0 26 11 80       	mov    %eax,0x801126a0
      wakeup(&ticks);
80106382:	c7 04 24 a0 26 11 80 	movl   $0x801126a0,(%esp)
80106389:	e8 32 e5 ff ff       	call   801048c0 <wakeup>
      release(&tickslock);
8010638e:	c7 04 24 60 1e 11 80 	movl   $0x80111e60,(%esp)
80106395:	e8 8b e7 ff ff       	call   80104b25 <release>
    }
    lapiceoi();
8010639a:	e8 42 cb ff ff       	call   80102ee1 <lapiceoi>
    break;
8010639f:	e9 41 01 00 00       	jmp    801064e5 <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
801063a4:	e8 40 c3 ff ff       	call   801026e9 <ideintr>
    lapiceoi();
801063a9:	e8 33 cb ff ff       	call   80102ee1 <lapiceoi>
    break;
801063ae:	e9 32 01 00 00       	jmp    801064e5 <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
801063b3:	e8 07 c9 ff ff       	call   80102cbf <kbdintr>
    lapiceoi();
801063b8:	e8 24 cb ff ff       	call   80102ee1 <lapiceoi>
    break;
801063bd:	e9 23 01 00 00       	jmp    801064e5 <trap+0x1f6>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
801063c2:	e8 a9 03 00 00       	call   80106770 <uartintr>
    lapiceoi();
801063c7:	e8 15 cb ff ff       	call   80102ee1 <lapiceoi>
    break;
801063cc:	e9 14 01 00 00       	jmp    801064e5 <trap+0x1f6>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
            cpu->id, tf->cs, tf->eip);
801063d1:	8b 45 08             	mov    0x8(%ebp),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801063d4:	8b 48 38             	mov    0x38(%eax),%ecx
            cpu->id, tf->cs, tf->eip);
801063d7:	8b 45 08             	mov    0x8(%ebp),%eax
801063da:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801063de:	0f b7 d0             	movzwl %ax,%edx
            cpu->id, tf->cs, tf->eip);
801063e1:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801063e7:	0f b6 00             	movzbl (%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801063ea:	0f b6 c0             	movzbl %al,%eax
801063ed:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
801063f1:	89 54 24 08          	mov    %edx,0x8(%esp)
801063f5:	89 44 24 04          	mov    %eax,0x4(%esp)
801063f9:	c7 04 24 d0 84 10 80 	movl   $0x801084d0,(%esp)
80106400:	e8 9c 9f ff ff       	call   801003a1 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
80106405:	e8 d7 ca ff ff       	call   80102ee1 <lapiceoi>
    break;
8010640a:	e9 d6 00 00 00       	jmp    801064e5 <trap+0x1f6>
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
8010640f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106415:	85 c0                	test   %eax,%eax
80106417:	74 11                	je     8010642a <trap+0x13b>
80106419:	8b 45 08             	mov    0x8(%ebp),%eax
8010641c:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106420:	0f b7 c0             	movzwl %ax,%eax
80106423:	83 e0 03             	and    $0x3,%eax
80106426:	85 c0                	test   %eax,%eax
80106428:	75 46                	jne    80106470 <trap+0x181>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
8010642a:	e8 1a fd ff ff       	call   80106149 <rcr2>
              tf->trapno, cpu->id, tf->eip, rcr2());
8010642f:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80106432:	8b 5a 38             	mov    0x38(%edx),%ebx
              tf->trapno, cpu->id, tf->eip, rcr2());
80106435:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
8010643c:	0f b6 12             	movzbl (%edx),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
8010643f:	0f b6 ca             	movzbl %dl,%ecx
              tf->trapno, cpu->id, tf->eip, rcr2());
80106442:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80106445:	8b 52 30             	mov    0x30(%edx),%edx
80106448:	89 44 24 10          	mov    %eax,0x10(%esp)
8010644c:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
80106450:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106454:	89 54 24 04          	mov    %edx,0x4(%esp)
80106458:	c7 04 24 f4 84 10 80 	movl   $0x801084f4,(%esp)
8010645f:	e8 3d 9f ff ff       	call   801003a1 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
80106464:	c7 04 24 26 85 10 80 	movl   $0x80108526,(%esp)
8010646b:	e8 cd a0 ff ff       	call   8010053d <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106470:	e8 d4 fc ff ff       	call   80106149 <rcr2>
80106475:	89 c2                	mov    %eax,%edx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80106477:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
8010647a:	8b 78 38             	mov    0x38(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
8010647d:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80106483:	0f b6 00             	movzbl (%eax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106486:	0f b6 f0             	movzbl %al,%esi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80106489:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
8010648c:	8b 58 34             	mov    0x34(%eax),%ebx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
8010648f:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106492:	8b 48 30             	mov    0x30(%eax),%ecx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80106495:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010649b:	83 c0 6c             	add    $0x6c,%eax
8010649e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801064a1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801064a7:	8b 40 10             	mov    0x10(%eax),%eax
801064aa:	89 54 24 1c          	mov    %edx,0x1c(%esp)
801064ae:	89 7c 24 18          	mov    %edi,0x18(%esp)
801064b2:	89 74 24 14          	mov    %esi,0x14(%esp)
801064b6:	89 5c 24 10          	mov    %ebx,0x10(%esp)
801064ba:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
801064be:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801064c1:	89 54 24 08          	mov    %edx,0x8(%esp)
801064c5:	89 44 24 04          	mov    %eax,0x4(%esp)
801064c9:	c7 04 24 2c 85 10 80 	movl   $0x8010852c,(%esp)
801064d0:	e8 cc 9e ff ff       	call   801003a1 <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
801064d5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801064db:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
801064e2:	eb 01                	jmp    801064e5 <trap+0x1f6>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
801064e4:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
801064e5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801064eb:	85 c0                	test   %eax,%eax
801064ed:	74 24                	je     80106513 <trap+0x224>
801064ef:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801064f5:	8b 40 24             	mov    0x24(%eax),%eax
801064f8:	85 c0                	test   %eax,%eax
801064fa:	74 17                	je     80106513 <trap+0x224>
801064fc:	8b 45 08             	mov    0x8(%ebp),%eax
801064ff:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106503:	0f b7 c0             	movzwl %ax,%eax
80106506:	83 e0 03             	and    $0x3,%eax
80106509:	83 f8 03             	cmp    $0x3,%eax
8010650c:	75 05                	jne    80106513 <trap+0x224>
    exit();
8010650e:	e8 04 df ff ff       	call   80104417 <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
80106513:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106519:	85 c0                	test   %eax,%eax
8010651b:	74 1e                	je     8010653b <trap+0x24c>
8010651d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106523:	8b 40 0c             	mov    0xc(%eax),%eax
80106526:	83 f8 04             	cmp    $0x4,%eax
80106529:	75 10                	jne    8010653b <trap+0x24c>
8010652b:	8b 45 08             	mov    0x8(%ebp),%eax
8010652e:	8b 40 30             	mov    0x30(%eax),%eax
80106531:	83 f8 20             	cmp    $0x20,%eax
80106534:	75 05                	jne    8010653b <trap+0x24c>
    yield();
80106536:	e8 4e e2 ff ff       	call   80104789 <yield>

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
8010653b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106541:	85 c0                	test   %eax,%eax
80106543:	74 27                	je     8010656c <trap+0x27d>
80106545:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010654b:	8b 40 24             	mov    0x24(%eax),%eax
8010654e:	85 c0                	test   %eax,%eax
80106550:	74 1a                	je     8010656c <trap+0x27d>
80106552:	8b 45 08             	mov    0x8(%ebp),%eax
80106555:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106559:	0f b7 c0             	movzwl %ax,%eax
8010655c:	83 e0 03             	and    $0x3,%eax
8010655f:	83 f8 03             	cmp    $0x3,%eax
80106562:	75 08                	jne    8010656c <trap+0x27d>
    exit();
80106564:	e8 ae de ff ff       	call   80104417 <exit>
80106569:	eb 01                	jmp    8010656c <trap+0x27d>
      exit();
    proc->tf = tf;
    syscall();
    if(proc->killed)
      exit();
    return;
8010656b:	90                   	nop
    yield();

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
    exit();
}
8010656c:	83 c4 3c             	add    $0x3c,%esp
8010656f:	5b                   	pop    %ebx
80106570:	5e                   	pop    %esi
80106571:	5f                   	pop    %edi
80106572:	5d                   	pop    %ebp
80106573:	c3                   	ret    

80106574 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80106574:	55                   	push   %ebp
80106575:	89 e5                	mov    %esp,%ebp
80106577:	53                   	push   %ebx
80106578:	83 ec 14             	sub    $0x14,%esp
8010657b:	8b 45 08             	mov    0x8(%ebp),%eax
8010657e:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80106582:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80106586:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
8010658a:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
8010658e:	ec                   	in     (%dx),%al
8010658f:	89 c3                	mov    %eax,%ebx
80106591:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80106594:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80106598:	83 c4 14             	add    $0x14,%esp
8010659b:	5b                   	pop    %ebx
8010659c:	5d                   	pop    %ebp
8010659d:	c3                   	ret    

8010659e <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
8010659e:	55                   	push   %ebp
8010659f:	89 e5                	mov    %esp,%ebp
801065a1:	83 ec 08             	sub    $0x8,%esp
801065a4:	8b 55 08             	mov    0x8(%ebp),%edx
801065a7:	8b 45 0c             	mov    0xc(%ebp),%eax
801065aa:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801065ae:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801065b1:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801065b5:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801065b9:	ee                   	out    %al,(%dx)
}
801065ba:	c9                   	leave  
801065bb:	c3                   	ret    

801065bc <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
801065bc:	55                   	push   %ebp
801065bd:	89 e5                	mov    %esp,%ebp
801065bf:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
801065c2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801065c9:	00 
801065ca:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
801065d1:	e8 c8 ff ff ff       	call   8010659e <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
801065d6:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
801065dd:	00 
801065de:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
801065e5:	e8 b4 ff ff ff       	call   8010659e <outb>
  outb(COM1+0, 115200/9600);
801065ea:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
801065f1:	00 
801065f2:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
801065f9:	e8 a0 ff ff ff       	call   8010659e <outb>
  outb(COM1+1, 0);
801065fe:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106605:	00 
80106606:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
8010660d:	e8 8c ff ff ff       	call   8010659e <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
80106612:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80106619:	00 
8010661a:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80106621:	e8 78 ff ff ff       	call   8010659e <outb>
  outb(COM1+4, 0);
80106626:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010662d:	00 
8010662e:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
80106635:	e8 64 ff ff ff       	call   8010659e <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
8010663a:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80106641:	00 
80106642:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80106649:	e8 50 ff ff ff       	call   8010659e <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
8010664e:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106655:	e8 1a ff ff ff       	call   80106574 <inb>
8010665a:	3c ff                	cmp    $0xff,%al
8010665c:	74 6c                	je     801066ca <uartinit+0x10e>
    return;
  uart = 1;
8010665e:	c7 05 4c b6 10 80 01 	movl   $0x1,0x8010b64c
80106665:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
80106668:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
8010666f:	e8 00 ff ff ff       	call   80106574 <inb>
  inb(COM1+0);
80106674:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
8010667b:	e8 f4 fe ff ff       	call   80106574 <inb>
  picenable(IRQ_COM1);
80106680:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80106687:	e8 1d d4 ff ff       	call   80103aa9 <picenable>
  ioapicenable(IRQ_COM1, 0);
8010668c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106693:	00 
80106694:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
8010669b:	e8 ce c2 ff ff       	call   8010296e <ioapicenable>
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
801066a0:	c7 45 f4 f0 85 10 80 	movl   $0x801085f0,-0xc(%ebp)
801066a7:	eb 15                	jmp    801066be <uartinit+0x102>
    uartputc(*p);
801066a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066ac:	0f b6 00             	movzbl (%eax),%eax
801066af:	0f be c0             	movsbl %al,%eax
801066b2:	89 04 24             	mov    %eax,(%esp)
801066b5:	e8 13 00 00 00       	call   801066cd <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
801066ba:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801066be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066c1:	0f b6 00             	movzbl (%eax),%eax
801066c4:	84 c0                	test   %al,%al
801066c6:	75 e1                	jne    801066a9 <uartinit+0xed>
801066c8:	eb 01                	jmp    801066cb <uartinit+0x10f>
  outb(COM1+4, 0);
  outb(COM1+1, 0x01);    // Enable receive interrupts.

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
    return;
801066ca:	90                   	nop
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
    uartputc(*p);
}
801066cb:	c9                   	leave  
801066cc:	c3                   	ret    

801066cd <uartputc>:

void
uartputc(int c)
{
801066cd:	55                   	push   %ebp
801066ce:	89 e5                	mov    %esp,%ebp
801066d0:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
801066d3:	a1 4c b6 10 80       	mov    0x8010b64c,%eax
801066d8:	85 c0                	test   %eax,%eax
801066da:	74 4d                	je     80106729 <uartputc+0x5c>
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
801066dc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801066e3:	eb 10                	jmp    801066f5 <uartputc+0x28>
    microdelay(10);
801066e5:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
801066ec:	e8 15 c8 ff ff       	call   80102f06 <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
801066f1:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801066f5:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
801066f9:	7f 16                	jg     80106711 <uartputc+0x44>
801066fb:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106702:	e8 6d fe ff ff       	call   80106574 <inb>
80106707:	0f b6 c0             	movzbl %al,%eax
8010670a:	83 e0 20             	and    $0x20,%eax
8010670d:	85 c0                	test   %eax,%eax
8010670f:	74 d4                	je     801066e5 <uartputc+0x18>
    microdelay(10);
  outb(COM1+0, c);
80106711:	8b 45 08             	mov    0x8(%ebp),%eax
80106714:	0f b6 c0             	movzbl %al,%eax
80106717:	89 44 24 04          	mov    %eax,0x4(%esp)
8010671b:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106722:	e8 77 fe ff ff       	call   8010659e <outb>
80106727:	eb 01                	jmp    8010672a <uartputc+0x5d>
uartputc(int c)
{
  int i;

  if(!uart)
    return;
80106729:	90                   	nop
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
    microdelay(10);
  outb(COM1+0, c);
}
8010672a:	c9                   	leave  
8010672b:	c3                   	ret    

8010672c <uartgetc>:

static int
uartgetc(void)
{
8010672c:	55                   	push   %ebp
8010672d:	89 e5                	mov    %esp,%ebp
8010672f:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
80106732:	a1 4c b6 10 80       	mov    0x8010b64c,%eax
80106737:	85 c0                	test   %eax,%eax
80106739:	75 07                	jne    80106742 <uartgetc+0x16>
    return -1;
8010673b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106740:	eb 2c                	jmp    8010676e <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
80106742:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106749:	e8 26 fe ff ff       	call   80106574 <inb>
8010674e:	0f b6 c0             	movzbl %al,%eax
80106751:	83 e0 01             	and    $0x1,%eax
80106754:	85 c0                	test   %eax,%eax
80106756:	75 07                	jne    8010675f <uartgetc+0x33>
    return -1;
80106758:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010675d:	eb 0f                	jmp    8010676e <uartgetc+0x42>
  return inb(COM1+0);
8010675f:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106766:	e8 09 fe ff ff       	call   80106574 <inb>
8010676b:	0f b6 c0             	movzbl %al,%eax
}
8010676e:	c9                   	leave  
8010676f:	c3                   	ret    

80106770 <uartintr>:

void
uartintr(void)
{
80106770:	55                   	push   %ebp
80106771:	89 e5                	mov    %esp,%ebp
80106773:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
80106776:	c7 04 24 2c 67 10 80 	movl   $0x8010672c,(%esp)
8010677d:	e8 2b a0 ff ff       	call   801007ad <consoleintr>
}
80106782:	c9                   	leave  
80106783:	c3                   	ret    

80106784 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80106784:	6a 00                	push   $0x0
  pushl $0
80106786:	6a 00                	push   $0x0
  jmp alltraps
80106788:	e9 67 f9 ff ff       	jmp    801060f4 <alltraps>

8010678d <vector1>:
.globl vector1
vector1:
  pushl $0
8010678d:	6a 00                	push   $0x0
  pushl $1
8010678f:	6a 01                	push   $0x1
  jmp alltraps
80106791:	e9 5e f9 ff ff       	jmp    801060f4 <alltraps>

80106796 <vector2>:
.globl vector2
vector2:
  pushl $0
80106796:	6a 00                	push   $0x0
  pushl $2
80106798:	6a 02                	push   $0x2
  jmp alltraps
8010679a:	e9 55 f9 ff ff       	jmp    801060f4 <alltraps>

8010679f <vector3>:
.globl vector3
vector3:
  pushl $0
8010679f:	6a 00                	push   $0x0
  pushl $3
801067a1:	6a 03                	push   $0x3
  jmp alltraps
801067a3:	e9 4c f9 ff ff       	jmp    801060f4 <alltraps>

801067a8 <vector4>:
.globl vector4
vector4:
  pushl $0
801067a8:	6a 00                	push   $0x0
  pushl $4
801067aa:	6a 04                	push   $0x4
  jmp alltraps
801067ac:	e9 43 f9 ff ff       	jmp    801060f4 <alltraps>

801067b1 <vector5>:
.globl vector5
vector5:
  pushl $0
801067b1:	6a 00                	push   $0x0
  pushl $5
801067b3:	6a 05                	push   $0x5
  jmp alltraps
801067b5:	e9 3a f9 ff ff       	jmp    801060f4 <alltraps>

801067ba <vector6>:
.globl vector6
vector6:
  pushl $0
801067ba:	6a 00                	push   $0x0
  pushl $6
801067bc:	6a 06                	push   $0x6
  jmp alltraps
801067be:	e9 31 f9 ff ff       	jmp    801060f4 <alltraps>

801067c3 <vector7>:
.globl vector7
vector7:
  pushl $0
801067c3:	6a 00                	push   $0x0
  pushl $7
801067c5:	6a 07                	push   $0x7
  jmp alltraps
801067c7:	e9 28 f9 ff ff       	jmp    801060f4 <alltraps>

801067cc <vector8>:
.globl vector8
vector8:
  pushl $8
801067cc:	6a 08                	push   $0x8
  jmp alltraps
801067ce:	e9 21 f9 ff ff       	jmp    801060f4 <alltraps>

801067d3 <vector9>:
.globl vector9
vector9:
  pushl $0
801067d3:	6a 00                	push   $0x0
  pushl $9
801067d5:	6a 09                	push   $0x9
  jmp alltraps
801067d7:	e9 18 f9 ff ff       	jmp    801060f4 <alltraps>

801067dc <vector10>:
.globl vector10
vector10:
  pushl $10
801067dc:	6a 0a                	push   $0xa
  jmp alltraps
801067de:	e9 11 f9 ff ff       	jmp    801060f4 <alltraps>

801067e3 <vector11>:
.globl vector11
vector11:
  pushl $11
801067e3:	6a 0b                	push   $0xb
  jmp alltraps
801067e5:	e9 0a f9 ff ff       	jmp    801060f4 <alltraps>

801067ea <vector12>:
.globl vector12
vector12:
  pushl $12
801067ea:	6a 0c                	push   $0xc
  jmp alltraps
801067ec:	e9 03 f9 ff ff       	jmp    801060f4 <alltraps>

801067f1 <vector13>:
.globl vector13
vector13:
  pushl $13
801067f1:	6a 0d                	push   $0xd
  jmp alltraps
801067f3:	e9 fc f8 ff ff       	jmp    801060f4 <alltraps>

801067f8 <vector14>:
.globl vector14
vector14:
  pushl $14
801067f8:	6a 0e                	push   $0xe
  jmp alltraps
801067fa:	e9 f5 f8 ff ff       	jmp    801060f4 <alltraps>

801067ff <vector15>:
.globl vector15
vector15:
  pushl $0
801067ff:	6a 00                	push   $0x0
  pushl $15
80106801:	6a 0f                	push   $0xf
  jmp alltraps
80106803:	e9 ec f8 ff ff       	jmp    801060f4 <alltraps>

80106808 <vector16>:
.globl vector16
vector16:
  pushl $0
80106808:	6a 00                	push   $0x0
  pushl $16
8010680a:	6a 10                	push   $0x10
  jmp alltraps
8010680c:	e9 e3 f8 ff ff       	jmp    801060f4 <alltraps>

80106811 <vector17>:
.globl vector17
vector17:
  pushl $17
80106811:	6a 11                	push   $0x11
  jmp alltraps
80106813:	e9 dc f8 ff ff       	jmp    801060f4 <alltraps>

80106818 <vector18>:
.globl vector18
vector18:
  pushl $0
80106818:	6a 00                	push   $0x0
  pushl $18
8010681a:	6a 12                	push   $0x12
  jmp alltraps
8010681c:	e9 d3 f8 ff ff       	jmp    801060f4 <alltraps>

80106821 <vector19>:
.globl vector19
vector19:
  pushl $0
80106821:	6a 00                	push   $0x0
  pushl $19
80106823:	6a 13                	push   $0x13
  jmp alltraps
80106825:	e9 ca f8 ff ff       	jmp    801060f4 <alltraps>

8010682a <vector20>:
.globl vector20
vector20:
  pushl $0
8010682a:	6a 00                	push   $0x0
  pushl $20
8010682c:	6a 14                	push   $0x14
  jmp alltraps
8010682e:	e9 c1 f8 ff ff       	jmp    801060f4 <alltraps>

80106833 <vector21>:
.globl vector21
vector21:
  pushl $0
80106833:	6a 00                	push   $0x0
  pushl $21
80106835:	6a 15                	push   $0x15
  jmp alltraps
80106837:	e9 b8 f8 ff ff       	jmp    801060f4 <alltraps>

8010683c <vector22>:
.globl vector22
vector22:
  pushl $0
8010683c:	6a 00                	push   $0x0
  pushl $22
8010683e:	6a 16                	push   $0x16
  jmp alltraps
80106840:	e9 af f8 ff ff       	jmp    801060f4 <alltraps>

80106845 <vector23>:
.globl vector23
vector23:
  pushl $0
80106845:	6a 00                	push   $0x0
  pushl $23
80106847:	6a 17                	push   $0x17
  jmp alltraps
80106849:	e9 a6 f8 ff ff       	jmp    801060f4 <alltraps>

8010684e <vector24>:
.globl vector24
vector24:
  pushl $0
8010684e:	6a 00                	push   $0x0
  pushl $24
80106850:	6a 18                	push   $0x18
  jmp alltraps
80106852:	e9 9d f8 ff ff       	jmp    801060f4 <alltraps>

80106857 <vector25>:
.globl vector25
vector25:
  pushl $0
80106857:	6a 00                	push   $0x0
  pushl $25
80106859:	6a 19                	push   $0x19
  jmp alltraps
8010685b:	e9 94 f8 ff ff       	jmp    801060f4 <alltraps>

80106860 <vector26>:
.globl vector26
vector26:
  pushl $0
80106860:	6a 00                	push   $0x0
  pushl $26
80106862:	6a 1a                	push   $0x1a
  jmp alltraps
80106864:	e9 8b f8 ff ff       	jmp    801060f4 <alltraps>

80106869 <vector27>:
.globl vector27
vector27:
  pushl $0
80106869:	6a 00                	push   $0x0
  pushl $27
8010686b:	6a 1b                	push   $0x1b
  jmp alltraps
8010686d:	e9 82 f8 ff ff       	jmp    801060f4 <alltraps>

80106872 <vector28>:
.globl vector28
vector28:
  pushl $0
80106872:	6a 00                	push   $0x0
  pushl $28
80106874:	6a 1c                	push   $0x1c
  jmp alltraps
80106876:	e9 79 f8 ff ff       	jmp    801060f4 <alltraps>

8010687b <vector29>:
.globl vector29
vector29:
  pushl $0
8010687b:	6a 00                	push   $0x0
  pushl $29
8010687d:	6a 1d                	push   $0x1d
  jmp alltraps
8010687f:	e9 70 f8 ff ff       	jmp    801060f4 <alltraps>

80106884 <vector30>:
.globl vector30
vector30:
  pushl $0
80106884:	6a 00                	push   $0x0
  pushl $30
80106886:	6a 1e                	push   $0x1e
  jmp alltraps
80106888:	e9 67 f8 ff ff       	jmp    801060f4 <alltraps>

8010688d <vector31>:
.globl vector31
vector31:
  pushl $0
8010688d:	6a 00                	push   $0x0
  pushl $31
8010688f:	6a 1f                	push   $0x1f
  jmp alltraps
80106891:	e9 5e f8 ff ff       	jmp    801060f4 <alltraps>

80106896 <vector32>:
.globl vector32
vector32:
  pushl $0
80106896:	6a 00                	push   $0x0
  pushl $32
80106898:	6a 20                	push   $0x20
  jmp alltraps
8010689a:	e9 55 f8 ff ff       	jmp    801060f4 <alltraps>

8010689f <vector33>:
.globl vector33
vector33:
  pushl $0
8010689f:	6a 00                	push   $0x0
  pushl $33
801068a1:	6a 21                	push   $0x21
  jmp alltraps
801068a3:	e9 4c f8 ff ff       	jmp    801060f4 <alltraps>

801068a8 <vector34>:
.globl vector34
vector34:
  pushl $0
801068a8:	6a 00                	push   $0x0
  pushl $34
801068aa:	6a 22                	push   $0x22
  jmp alltraps
801068ac:	e9 43 f8 ff ff       	jmp    801060f4 <alltraps>

801068b1 <vector35>:
.globl vector35
vector35:
  pushl $0
801068b1:	6a 00                	push   $0x0
  pushl $35
801068b3:	6a 23                	push   $0x23
  jmp alltraps
801068b5:	e9 3a f8 ff ff       	jmp    801060f4 <alltraps>

801068ba <vector36>:
.globl vector36
vector36:
  pushl $0
801068ba:	6a 00                	push   $0x0
  pushl $36
801068bc:	6a 24                	push   $0x24
  jmp alltraps
801068be:	e9 31 f8 ff ff       	jmp    801060f4 <alltraps>

801068c3 <vector37>:
.globl vector37
vector37:
  pushl $0
801068c3:	6a 00                	push   $0x0
  pushl $37
801068c5:	6a 25                	push   $0x25
  jmp alltraps
801068c7:	e9 28 f8 ff ff       	jmp    801060f4 <alltraps>

801068cc <vector38>:
.globl vector38
vector38:
  pushl $0
801068cc:	6a 00                	push   $0x0
  pushl $38
801068ce:	6a 26                	push   $0x26
  jmp alltraps
801068d0:	e9 1f f8 ff ff       	jmp    801060f4 <alltraps>

801068d5 <vector39>:
.globl vector39
vector39:
  pushl $0
801068d5:	6a 00                	push   $0x0
  pushl $39
801068d7:	6a 27                	push   $0x27
  jmp alltraps
801068d9:	e9 16 f8 ff ff       	jmp    801060f4 <alltraps>

801068de <vector40>:
.globl vector40
vector40:
  pushl $0
801068de:	6a 00                	push   $0x0
  pushl $40
801068e0:	6a 28                	push   $0x28
  jmp alltraps
801068e2:	e9 0d f8 ff ff       	jmp    801060f4 <alltraps>

801068e7 <vector41>:
.globl vector41
vector41:
  pushl $0
801068e7:	6a 00                	push   $0x0
  pushl $41
801068e9:	6a 29                	push   $0x29
  jmp alltraps
801068eb:	e9 04 f8 ff ff       	jmp    801060f4 <alltraps>

801068f0 <vector42>:
.globl vector42
vector42:
  pushl $0
801068f0:	6a 00                	push   $0x0
  pushl $42
801068f2:	6a 2a                	push   $0x2a
  jmp alltraps
801068f4:	e9 fb f7 ff ff       	jmp    801060f4 <alltraps>

801068f9 <vector43>:
.globl vector43
vector43:
  pushl $0
801068f9:	6a 00                	push   $0x0
  pushl $43
801068fb:	6a 2b                	push   $0x2b
  jmp alltraps
801068fd:	e9 f2 f7 ff ff       	jmp    801060f4 <alltraps>

80106902 <vector44>:
.globl vector44
vector44:
  pushl $0
80106902:	6a 00                	push   $0x0
  pushl $44
80106904:	6a 2c                	push   $0x2c
  jmp alltraps
80106906:	e9 e9 f7 ff ff       	jmp    801060f4 <alltraps>

8010690b <vector45>:
.globl vector45
vector45:
  pushl $0
8010690b:	6a 00                	push   $0x0
  pushl $45
8010690d:	6a 2d                	push   $0x2d
  jmp alltraps
8010690f:	e9 e0 f7 ff ff       	jmp    801060f4 <alltraps>

80106914 <vector46>:
.globl vector46
vector46:
  pushl $0
80106914:	6a 00                	push   $0x0
  pushl $46
80106916:	6a 2e                	push   $0x2e
  jmp alltraps
80106918:	e9 d7 f7 ff ff       	jmp    801060f4 <alltraps>

8010691d <vector47>:
.globl vector47
vector47:
  pushl $0
8010691d:	6a 00                	push   $0x0
  pushl $47
8010691f:	6a 2f                	push   $0x2f
  jmp alltraps
80106921:	e9 ce f7 ff ff       	jmp    801060f4 <alltraps>

80106926 <vector48>:
.globl vector48
vector48:
  pushl $0
80106926:	6a 00                	push   $0x0
  pushl $48
80106928:	6a 30                	push   $0x30
  jmp alltraps
8010692a:	e9 c5 f7 ff ff       	jmp    801060f4 <alltraps>

8010692f <vector49>:
.globl vector49
vector49:
  pushl $0
8010692f:	6a 00                	push   $0x0
  pushl $49
80106931:	6a 31                	push   $0x31
  jmp alltraps
80106933:	e9 bc f7 ff ff       	jmp    801060f4 <alltraps>

80106938 <vector50>:
.globl vector50
vector50:
  pushl $0
80106938:	6a 00                	push   $0x0
  pushl $50
8010693a:	6a 32                	push   $0x32
  jmp alltraps
8010693c:	e9 b3 f7 ff ff       	jmp    801060f4 <alltraps>

80106941 <vector51>:
.globl vector51
vector51:
  pushl $0
80106941:	6a 00                	push   $0x0
  pushl $51
80106943:	6a 33                	push   $0x33
  jmp alltraps
80106945:	e9 aa f7 ff ff       	jmp    801060f4 <alltraps>

8010694a <vector52>:
.globl vector52
vector52:
  pushl $0
8010694a:	6a 00                	push   $0x0
  pushl $52
8010694c:	6a 34                	push   $0x34
  jmp alltraps
8010694e:	e9 a1 f7 ff ff       	jmp    801060f4 <alltraps>

80106953 <vector53>:
.globl vector53
vector53:
  pushl $0
80106953:	6a 00                	push   $0x0
  pushl $53
80106955:	6a 35                	push   $0x35
  jmp alltraps
80106957:	e9 98 f7 ff ff       	jmp    801060f4 <alltraps>

8010695c <vector54>:
.globl vector54
vector54:
  pushl $0
8010695c:	6a 00                	push   $0x0
  pushl $54
8010695e:	6a 36                	push   $0x36
  jmp alltraps
80106960:	e9 8f f7 ff ff       	jmp    801060f4 <alltraps>

80106965 <vector55>:
.globl vector55
vector55:
  pushl $0
80106965:	6a 00                	push   $0x0
  pushl $55
80106967:	6a 37                	push   $0x37
  jmp alltraps
80106969:	e9 86 f7 ff ff       	jmp    801060f4 <alltraps>

8010696e <vector56>:
.globl vector56
vector56:
  pushl $0
8010696e:	6a 00                	push   $0x0
  pushl $56
80106970:	6a 38                	push   $0x38
  jmp alltraps
80106972:	e9 7d f7 ff ff       	jmp    801060f4 <alltraps>

80106977 <vector57>:
.globl vector57
vector57:
  pushl $0
80106977:	6a 00                	push   $0x0
  pushl $57
80106979:	6a 39                	push   $0x39
  jmp alltraps
8010697b:	e9 74 f7 ff ff       	jmp    801060f4 <alltraps>

80106980 <vector58>:
.globl vector58
vector58:
  pushl $0
80106980:	6a 00                	push   $0x0
  pushl $58
80106982:	6a 3a                	push   $0x3a
  jmp alltraps
80106984:	e9 6b f7 ff ff       	jmp    801060f4 <alltraps>

80106989 <vector59>:
.globl vector59
vector59:
  pushl $0
80106989:	6a 00                	push   $0x0
  pushl $59
8010698b:	6a 3b                	push   $0x3b
  jmp alltraps
8010698d:	e9 62 f7 ff ff       	jmp    801060f4 <alltraps>

80106992 <vector60>:
.globl vector60
vector60:
  pushl $0
80106992:	6a 00                	push   $0x0
  pushl $60
80106994:	6a 3c                	push   $0x3c
  jmp alltraps
80106996:	e9 59 f7 ff ff       	jmp    801060f4 <alltraps>

8010699b <vector61>:
.globl vector61
vector61:
  pushl $0
8010699b:	6a 00                	push   $0x0
  pushl $61
8010699d:	6a 3d                	push   $0x3d
  jmp alltraps
8010699f:	e9 50 f7 ff ff       	jmp    801060f4 <alltraps>

801069a4 <vector62>:
.globl vector62
vector62:
  pushl $0
801069a4:	6a 00                	push   $0x0
  pushl $62
801069a6:	6a 3e                	push   $0x3e
  jmp alltraps
801069a8:	e9 47 f7 ff ff       	jmp    801060f4 <alltraps>

801069ad <vector63>:
.globl vector63
vector63:
  pushl $0
801069ad:	6a 00                	push   $0x0
  pushl $63
801069af:	6a 3f                	push   $0x3f
  jmp alltraps
801069b1:	e9 3e f7 ff ff       	jmp    801060f4 <alltraps>

801069b6 <vector64>:
.globl vector64
vector64:
  pushl $0
801069b6:	6a 00                	push   $0x0
  pushl $64
801069b8:	6a 40                	push   $0x40
  jmp alltraps
801069ba:	e9 35 f7 ff ff       	jmp    801060f4 <alltraps>

801069bf <vector65>:
.globl vector65
vector65:
  pushl $0
801069bf:	6a 00                	push   $0x0
  pushl $65
801069c1:	6a 41                	push   $0x41
  jmp alltraps
801069c3:	e9 2c f7 ff ff       	jmp    801060f4 <alltraps>

801069c8 <vector66>:
.globl vector66
vector66:
  pushl $0
801069c8:	6a 00                	push   $0x0
  pushl $66
801069ca:	6a 42                	push   $0x42
  jmp alltraps
801069cc:	e9 23 f7 ff ff       	jmp    801060f4 <alltraps>

801069d1 <vector67>:
.globl vector67
vector67:
  pushl $0
801069d1:	6a 00                	push   $0x0
  pushl $67
801069d3:	6a 43                	push   $0x43
  jmp alltraps
801069d5:	e9 1a f7 ff ff       	jmp    801060f4 <alltraps>

801069da <vector68>:
.globl vector68
vector68:
  pushl $0
801069da:	6a 00                	push   $0x0
  pushl $68
801069dc:	6a 44                	push   $0x44
  jmp alltraps
801069de:	e9 11 f7 ff ff       	jmp    801060f4 <alltraps>

801069e3 <vector69>:
.globl vector69
vector69:
  pushl $0
801069e3:	6a 00                	push   $0x0
  pushl $69
801069e5:	6a 45                	push   $0x45
  jmp alltraps
801069e7:	e9 08 f7 ff ff       	jmp    801060f4 <alltraps>

801069ec <vector70>:
.globl vector70
vector70:
  pushl $0
801069ec:	6a 00                	push   $0x0
  pushl $70
801069ee:	6a 46                	push   $0x46
  jmp alltraps
801069f0:	e9 ff f6 ff ff       	jmp    801060f4 <alltraps>

801069f5 <vector71>:
.globl vector71
vector71:
  pushl $0
801069f5:	6a 00                	push   $0x0
  pushl $71
801069f7:	6a 47                	push   $0x47
  jmp alltraps
801069f9:	e9 f6 f6 ff ff       	jmp    801060f4 <alltraps>

801069fe <vector72>:
.globl vector72
vector72:
  pushl $0
801069fe:	6a 00                	push   $0x0
  pushl $72
80106a00:	6a 48                	push   $0x48
  jmp alltraps
80106a02:	e9 ed f6 ff ff       	jmp    801060f4 <alltraps>

80106a07 <vector73>:
.globl vector73
vector73:
  pushl $0
80106a07:	6a 00                	push   $0x0
  pushl $73
80106a09:	6a 49                	push   $0x49
  jmp alltraps
80106a0b:	e9 e4 f6 ff ff       	jmp    801060f4 <alltraps>

80106a10 <vector74>:
.globl vector74
vector74:
  pushl $0
80106a10:	6a 00                	push   $0x0
  pushl $74
80106a12:	6a 4a                	push   $0x4a
  jmp alltraps
80106a14:	e9 db f6 ff ff       	jmp    801060f4 <alltraps>

80106a19 <vector75>:
.globl vector75
vector75:
  pushl $0
80106a19:	6a 00                	push   $0x0
  pushl $75
80106a1b:	6a 4b                	push   $0x4b
  jmp alltraps
80106a1d:	e9 d2 f6 ff ff       	jmp    801060f4 <alltraps>

80106a22 <vector76>:
.globl vector76
vector76:
  pushl $0
80106a22:	6a 00                	push   $0x0
  pushl $76
80106a24:	6a 4c                	push   $0x4c
  jmp alltraps
80106a26:	e9 c9 f6 ff ff       	jmp    801060f4 <alltraps>

80106a2b <vector77>:
.globl vector77
vector77:
  pushl $0
80106a2b:	6a 00                	push   $0x0
  pushl $77
80106a2d:	6a 4d                	push   $0x4d
  jmp alltraps
80106a2f:	e9 c0 f6 ff ff       	jmp    801060f4 <alltraps>

80106a34 <vector78>:
.globl vector78
vector78:
  pushl $0
80106a34:	6a 00                	push   $0x0
  pushl $78
80106a36:	6a 4e                	push   $0x4e
  jmp alltraps
80106a38:	e9 b7 f6 ff ff       	jmp    801060f4 <alltraps>

80106a3d <vector79>:
.globl vector79
vector79:
  pushl $0
80106a3d:	6a 00                	push   $0x0
  pushl $79
80106a3f:	6a 4f                	push   $0x4f
  jmp alltraps
80106a41:	e9 ae f6 ff ff       	jmp    801060f4 <alltraps>

80106a46 <vector80>:
.globl vector80
vector80:
  pushl $0
80106a46:	6a 00                	push   $0x0
  pushl $80
80106a48:	6a 50                	push   $0x50
  jmp alltraps
80106a4a:	e9 a5 f6 ff ff       	jmp    801060f4 <alltraps>

80106a4f <vector81>:
.globl vector81
vector81:
  pushl $0
80106a4f:	6a 00                	push   $0x0
  pushl $81
80106a51:	6a 51                	push   $0x51
  jmp alltraps
80106a53:	e9 9c f6 ff ff       	jmp    801060f4 <alltraps>

80106a58 <vector82>:
.globl vector82
vector82:
  pushl $0
80106a58:	6a 00                	push   $0x0
  pushl $82
80106a5a:	6a 52                	push   $0x52
  jmp alltraps
80106a5c:	e9 93 f6 ff ff       	jmp    801060f4 <alltraps>

80106a61 <vector83>:
.globl vector83
vector83:
  pushl $0
80106a61:	6a 00                	push   $0x0
  pushl $83
80106a63:	6a 53                	push   $0x53
  jmp alltraps
80106a65:	e9 8a f6 ff ff       	jmp    801060f4 <alltraps>

80106a6a <vector84>:
.globl vector84
vector84:
  pushl $0
80106a6a:	6a 00                	push   $0x0
  pushl $84
80106a6c:	6a 54                	push   $0x54
  jmp alltraps
80106a6e:	e9 81 f6 ff ff       	jmp    801060f4 <alltraps>

80106a73 <vector85>:
.globl vector85
vector85:
  pushl $0
80106a73:	6a 00                	push   $0x0
  pushl $85
80106a75:	6a 55                	push   $0x55
  jmp alltraps
80106a77:	e9 78 f6 ff ff       	jmp    801060f4 <alltraps>

80106a7c <vector86>:
.globl vector86
vector86:
  pushl $0
80106a7c:	6a 00                	push   $0x0
  pushl $86
80106a7e:	6a 56                	push   $0x56
  jmp alltraps
80106a80:	e9 6f f6 ff ff       	jmp    801060f4 <alltraps>

80106a85 <vector87>:
.globl vector87
vector87:
  pushl $0
80106a85:	6a 00                	push   $0x0
  pushl $87
80106a87:	6a 57                	push   $0x57
  jmp alltraps
80106a89:	e9 66 f6 ff ff       	jmp    801060f4 <alltraps>

80106a8e <vector88>:
.globl vector88
vector88:
  pushl $0
80106a8e:	6a 00                	push   $0x0
  pushl $88
80106a90:	6a 58                	push   $0x58
  jmp alltraps
80106a92:	e9 5d f6 ff ff       	jmp    801060f4 <alltraps>

80106a97 <vector89>:
.globl vector89
vector89:
  pushl $0
80106a97:	6a 00                	push   $0x0
  pushl $89
80106a99:	6a 59                	push   $0x59
  jmp alltraps
80106a9b:	e9 54 f6 ff ff       	jmp    801060f4 <alltraps>

80106aa0 <vector90>:
.globl vector90
vector90:
  pushl $0
80106aa0:	6a 00                	push   $0x0
  pushl $90
80106aa2:	6a 5a                	push   $0x5a
  jmp alltraps
80106aa4:	e9 4b f6 ff ff       	jmp    801060f4 <alltraps>

80106aa9 <vector91>:
.globl vector91
vector91:
  pushl $0
80106aa9:	6a 00                	push   $0x0
  pushl $91
80106aab:	6a 5b                	push   $0x5b
  jmp alltraps
80106aad:	e9 42 f6 ff ff       	jmp    801060f4 <alltraps>

80106ab2 <vector92>:
.globl vector92
vector92:
  pushl $0
80106ab2:	6a 00                	push   $0x0
  pushl $92
80106ab4:	6a 5c                	push   $0x5c
  jmp alltraps
80106ab6:	e9 39 f6 ff ff       	jmp    801060f4 <alltraps>

80106abb <vector93>:
.globl vector93
vector93:
  pushl $0
80106abb:	6a 00                	push   $0x0
  pushl $93
80106abd:	6a 5d                	push   $0x5d
  jmp alltraps
80106abf:	e9 30 f6 ff ff       	jmp    801060f4 <alltraps>

80106ac4 <vector94>:
.globl vector94
vector94:
  pushl $0
80106ac4:	6a 00                	push   $0x0
  pushl $94
80106ac6:	6a 5e                	push   $0x5e
  jmp alltraps
80106ac8:	e9 27 f6 ff ff       	jmp    801060f4 <alltraps>

80106acd <vector95>:
.globl vector95
vector95:
  pushl $0
80106acd:	6a 00                	push   $0x0
  pushl $95
80106acf:	6a 5f                	push   $0x5f
  jmp alltraps
80106ad1:	e9 1e f6 ff ff       	jmp    801060f4 <alltraps>

80106ad6 <vector96>:
.globl vector96
vector96:
  pushl $0
80106ad6:	6a 00                	push   $0x0
  pushl $96
80106ad8:	6a 60                	push   $0x60
  jmp alltraps
80106ada:	e9 15 f6 ff ff       	jmp    801060f4 <alltraps>

80106adf <vector97>:
.globl vector97
vector97:
  pushl $0
80106adf:	6a 00                	push   $0x0
  pushl $97
80106ae1:	6a 61                	push   $0x61
  jmp alltraps
80106ae3:	e9 0c f6 ff ff       	jmp    801060f4 <alltraps>

80106ae8 <vector98>:
.globl vector98
vector98:
  pushl $0
80106ae8:	6a 00                	push   $0x0
  pushl $98
80106aea:	6a 62                	push   $0x62
  jmp alltraps
80106aec:	e9 03 f6 ff ff       	jmp    801060f4 <alltraps>

80106af1 <vector99>:
.globl vector99
vector99:
  pushl $0
80106af1:	6a 00                	push   $0x0
  pushl $99
80106af3:	6a 63                	push   $0x63
  jmp alltraps
80106af5:	e9 fa f5 ff ff       	jmp    801060f4 <alltraps>

80106afa <vector100>:
.globl vector100
vector100:
  pushl $0
80106afa:	6a 00                	push   $0x0
  pushl $100
80106afc:	6a 64                	push   $0x64
  jmp alltraps
80106afe:	e9 f1 f5 ff ff       	jmp    801060f4 <alltraps>

80106b03 <vector101>:
.globl vector101
vector101:
  pushl $0
80106b03:	6a 00                	push   $0x0
  pushl $101
80106b05:	6a 65                	push   $0x65
  jmp alltraps
80106b07:	e9 e8 f5 ff ff       	jmp    801060f4 <alltraps>

80106b0c <vector102>:
.globl vector102
vector102:
  pushl $0
80106b0c:	6a 00                	push   $0x0
  pushl $102
80106b0e:	6a 66                	push   $0x66
  jmp alltraps
80106b10:	e9 df f5 ff ff       	jmp    801060f4 <alltraps>

80106b15 <vector103>:
.globl vector103
vector103:
  pushl $0
80106b15:	6a 00                	push   $0x0
  pushl $103
80106b17:	6a 67                	push   $0x67
  jmp alltraps
80106b19:	e9 d6 f5 ff ff       	jmp    801060f4 <alltraps>

80106b1e <vector104>:
.globl vector104
vector104:
  pushl $0
80106b1e:	6a 00                	push   $0x0
  pushl $104
80106b20:	6a 68                	push   $0x68
  jmp alltraps
80106b22:	e9 cd f5 ff ff       	jmp    801060f4 <alltraps>

80106b27 <vector105>:
.globl vector105
vector105:
  pushl $0
80106b27:	6a 00                	push   $0x0
  pushl $105
80106b29:	6a 69                	push   $0x69
  jmp alltraps
80106b2b:	e9 c4 f5 ff ff       	jmp    801060f4 <alltraps>

80106b30 <vector106>:
.globl vector106
vector106:
  pushl $0
80106b30:	6a 00                	push   $0x0
  pushl $106
80106b32:	6a 6a                	push   $0x6a
  jmp alltraps
80106b34:	e9 bb f5 ff ff       	jmp    801060f4 <alltraps>

80106b39 <vector107>:
.globl vector107
vector107:
  pushl $0
80106b39:	6a 00                	push   $0x0
  pushl $107
80106b3b:	6a 6b                	push   $0x6b
  jmp alltraps
80106b3d:	e9 b2 f5 ff ff       	jmp    801060f4 <alltraps>

80106b42 <vector108>:
.globl vector108
vector108:
  pushl $0
80106b42:	6a 00                	push   $0x0
  pushl $108
80106b44:	6a 6c                	push   $0x6c
  jmp alltraps
80106b46:	e9 a9 f5 ff ff       	jmp    801060f4 <alltraps>

80106b4b <vector109>:
.globl vector109
vector109:
  pushl $0
80106b4b:	6a 00                	push   $0x0
  pushl $109
80106b4d:	6a 6d                	push   $0x6d
  jmp alltraps
80106b4f:	e9 a0 f5 ff ff       	jmp    801060f4 <alltraps>

80106b54 <vector110>:
.globl vector110
vector110:
  pushl $0
80106b54:	6a 00                	push   $0x0
  pushl $110
80106b56:	6a 6e                	push   $0x6e
  jmp alltraps
80106b58:	e9 97 f5 ff ff       	jmp    801060f4 <alltraps>

80106b5d <vector111>:
.globl vector111
vector111:
  pushl $0
80106b5d:	6a 00                	push   $0x0
  pushl $111
80106b5f:	6a 6f                	push   $0x6f
  jmp alltraps
80106b61:	e9 8e f5 ff ff       	jmp    801060f4 <alltraps>

80106b66 <vector112>:
.globl vector112
vector112:
  pushl $0
80106b66:	6a 00                	push   $0x0
  pushl $112
80106b68:	6a 70                	push   $0x70
  jmp alltraps
80106b6a:	e9 85 f5 ff ff       	jmp    801060f4 <alltraps>

80106b6f <vector113>:
.globl vector113
vector113:
  pushl $0
80106b6f:	6a 00                	push   $0x0
  pushl $113
80106b71:	6a 71                	push   $0x71
  jmp alltraps
80106b73:	e9 7c f5 ff ff       	jmp    801060f4 <alltraps>

80106b78 <vector114>:
.globl vector114
vector114:
  pushl $0
80106b78:	6a 00                	push   $0x0
  pushl $114
80106b7a:	6a 72                	push   $0x72
  jmp alltraps
80106b7c:	e9 73 f5 ff ff       	jmp    801060f4 <alltraps>

80106b81 <vector115>:
.globl vector115
vector115:
  pushl $0
80106b81:	6a 00                	push   $0x0
  pushl $115
80106b83:	6a 73                	push   $0x73
  jmp alltraps
80106b85:	e9 6a f5 ff ff       	jmp    801060f4 <alltraps>

80106b8a <vector116>:
.globl vector116
vector116:
  pushl $0
80106b8a:	6a 00                	push   $0x0
  pushl $116
80106b8c:	6a 74                	push   $0x74
  jmp alltraps
80106b8e:	e9 61 f5 ff ff       	jmp    801060f4 <alltraps>

80106b93 <vector117>:
.globl vector117
vector117:
  pushl $0
80106b93:	6a 00                	push   $0x0
  pushl $117
80106b95:	6a 75                	push   $0x75
  jmp alltraps
80106b97:	e9 58 f5 ff ff       	jmp    801060f4 <alltraps>

80106b9c <vector118>:
.globl vector118
vector118:
  pushl $0
80106b9c:	6a 00                	push   $0x0
  pushl $118
80106b9e:	6a 76                	push   $0x76
  jmp alltraps
80106ba0:	e9 4f f5 ff ff       	jmp    801060f4 <alltraps>

80106ba5 <vector119>:
.globl vector119
vector119:
  pushl $0
80106ba5:	6a 00                	push   $0x0
  pushl $119
80106ba7:	6a 77                	push   $0x77
  jmp alltraps
80106ba9:	e9 46 f5 ff ff       	jmp    801060f4 <alltraps>

80106bae <vector120>:
.globl vector120
vector120:
  pushl $0
80106bae:	6a 00                	push   $0x0
  pushl $120
80106bb0:	6a 78                	push   $0x78
  jmp alltraps
80106bb2:	e9 3d f5 ff ff       	jmp    801060f4 <alltraps>

80106bb7 <vector121>:
.globl vector121
vector121:
  pushl $0
80106bb7:	6a 00                	push   $0x0
  pushl $121
80106bb9:	6a 79                	push   $0x79
  jmp alltraps
80106bbb:	e9 34 f5 ff ff       	jmp    801060f4 <alltraps>

80106bc0 <vector122>:
.globl vector122
vector122:
  pushl $0
80106bc0:	6a 00                	push   $0x0
  pushl $122
80106bc2:	6a 7a                	push   $0x7a
  jmp alltraps
80106bc4:	e9 2b f5 ff ff       	jmp    801060f4 <alltraps>

80106bc9 <vector123>:
.globl vector123
vector123:
  pushl $0
80106bc9:	6a 00                	push   $0x0
  pushl $123
80106bcb:	6a 7b                	push   $0x7b
  jmp alltraps
80106bcd:	e9 22 f5 ff ff       	jmp    801060f4 <alltraps>

80106bd2 <vector124>:
.globl vector124
vector124:
  pushl $0
80106bd2:	6a 00                	push   $0x0
  pushl $124
80106bd4:	6a 7c                	push   $0x7c
  jmp alltraps
80106bd6:	e9 19 f5 ff ff       	jmp    801060f4 <alltraps>

80106bdb <vector125>:
.globl vector125
vector125:
  pushl $0
80106bdb:	6a 00                	push   $0x0
  pushl $125
80106bdd:	6a 7d                	push   $0x7d
  jmp alltraps
80106bdf:	e9 10 f5 ff ff       	jmp    801060f4 <alltraps>

80106be4 <vector126>:
.globl vector126
vector126:
  pushl $0
80106be4:	6a 00                	push   $0x0
  pushl $126
80106be6:	6a 7e                	push   $0x7e
  jmp alltraps
80106be8:	e9 07 f5 ff ff       	jmp    801060f4 <alltraps>

80106bed <vector127>:
.globl vector127
vector127:
  pushl $0
80106bed:	6a 00                	push   $0x0
  pushl $127
80106bef:	6a 7f                	push   $0x7f
  jmp alltraps
80106bf1:	e9 fe f4 ff ff       	jmp    801060f4 <alltraps>

80106bf6 <vector128>:
.globl vector128
vector128:
  pushl $0
80106bf6:	6a 00                	push   $0x0
  pushl $128
80106bf8:	68 80 00 00 00       	push   $0x80
  jmp alltraps
80106bfd:	e9 f2 f4 ff ff       	jmp    801060f4 <alltraps>

80106c02 <vector129>:
.globl vector129
vector129:
  pushl $0
80106c02:	6a 00                	push   $0x0
  pushl $129
80106c04:	68 81 00 00 00       	push   $0x81
  jmp alltraps
80106c09:	e9 e6 f4 ff ff       	jmp    801060f4 <alltraps>

80106c0e <vector130>:
.globl vector130
vector130:
  pushl $0
80106c0e:	6a 00                	push   $0x0
  pushl $130
80106c10:	68 82 00 00 00       	push   $0x82
  jmp alltraps
80106c15:	e9 da f4 ff ff       	jmp    801060f4 <alltraps>

80106c1a <vector131>:
.globl vector131
vector131:
  pushl $0
80106c1a:	6a 00                	push   $0x0
  pushl $131
80106c1c:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80106c21:	e9 ce f4 ff ff       	jmp    801060f4 <alltraps>

80106c26 <vector132>:
.globl vector132
vector132:
  pushl $0
80106c26:	6a 00                	push   $0x0
  pushl $132
80106c28:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80106c2d:	e9 c2 f4 ff ff       	jmp    801060f4 <alltraps>

80106c32 <vector133>:
.globl vector133
vector133:
  pushl $0
80106c32:	6a 00                	push   $0x0
  pushl $133
80106c34:	68 85 00 00 00       	push   $0x85
  jmp alltraps
80106c39:	e9 b6 f4 ff ff       	jmp    801060f4 <alltraps>

80106c3e <vector134>:
.globl vector134
vector134:
  pushl $0
80106c3e:	6a 00                	push   $0x0
  pushl $134
80106c40:	68 86 00 00 00       	push   $0x86
  jmp alltraps
80106c45:	e9 aa f4 ff ff       	jmp    801060f4 <alltraps>

80106c4a <vector135>:
.globl vector135
vector135:
  pushl $0
80106c4a:	6a 00                	push   $0x0
  pushl $135
80106c4c:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80106c51:	e9 9e f4 ff ff       	jmp    801060f4 <alltraps>

80106c56 <vector136>:
.globl vector136
vector136:
  pushl $0
80106c56:	6a 00                	push   $0x0
  pushl $136
80106c58:	68 88 00 00 00       	push   $0x88
  jmp alltraps
80106c5d:	e9 92 f4 ff ff       	jmp    801060f4 <alltraps>

80106c62 <vector137>:
.globl vector137
vector137:
  pushl $0
80106c62:	6a 00                	push   $0x0
  pushl $137
80106c64:	68 89 00 00 00       	push   $0x89
  jmp alltraps
80106c69:	e9 86 f4 ff ff       	jmp    801060f4 <alltraps>

80106c6e <vector138>:
.globl vector138
vector138:
  pushl $0
80106c6e:	6a 00                	push   $0x0
  pushl $138
80106c70:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
80106c75:	e9 7a f4 ff ff       	jmp    801060f4 <alltraps>

80106c7a <vector139>:
.globl vector139
vector139:
  pushl $0
80106c7a:	6a 00                	push   $0x0
  pushl $139
80106c7c:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80106c81:	e9 6e f4 ff ff       	jmp    801060f4 <alltraps>

80106c86 <vector140>:
.globl vector140
vector140:
  pushl $0
80106c86:	6a 00                	push   $0x0
  pushl $140
80106c88:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
80106c8d:	e9 62 f4 ff ff       	jmp    801060f4 <alltraps>

80106c92 <vector141>:
.globl vector141
vector141:
  pushl $0
80106c92:	6a 00                	push   $0x0
  pushl $141
80106c94:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80106c99:	e9 56 f4 ff ff       	jmp    801060f4 <alltraps>

80106c9e <vector142>:
.globl vector142
vector142:
  pushl $0
80106c9e:	6a 00                	push   $0x0
  pushl $142
80106ca0:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80106ca5:	e9 4a f4 ff ff       	jmp    801060f4 <alltraps>

80106caa <vector143>:
.globl vector143
vector143:
  pushl $0
80106caa:	6a 00                	push   $0x0
  pushl $143
80106cac:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80106cb1:	e9 3e f4 ff ff       	jmp    801060f4 <alltraps>

80106cb6 <vector144>:
.globl vector144
vector144:
  pushl $0
80106cb6:	6a 00                	push   $0x0
  pushl $144
80106cb8:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80106cbd:	e9 32 f4 ff ff       	jmp    801060f4 <alltraps>

80106cc2 <vector145>:
.globl vector145
vector145:
  pushl $0
80106cc2:	6a 00                	push   $0x0
  pushl $145
80106cc4:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80106cc9:	e9 26 f4 ff ff       	jmp    801060f4 <alltraps>

80106cce <vector146>:
.globl vector146
vector146:
  pushl $0
80106cce:	6a 00                	push   $0x0
  pushl $146
80106cd0:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80106cd5:	e9 1a f4 ff ff       	jmp    801060f4 <alltraps>

80106cda <vector147>:
.globl vector147
vector147:
  pushl $0
80106cda:	6a 00                	push   $0x0
  pushl $147
80106cdc:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80106ce1:	e9 0e f4 ff ff       	jmp    801060f4 <alltraps>

80106ce6 <vector148>:
.globl vector148
vector148:
  pushl $0
80106ce6:	6a 00                	push   $0x0
  pushl $148
80106ce8:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80106ced:	e9 02 f4 ff ff       	jmp    801060f4 <alltraps>

80106cf2 <vector149>:
.globl vector149
vector149:
  pushl $0
80106cf2:	6a 00                	push   $0x0
  pushl $149
80106cf4:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80106cf9:	e9 f6 f3 ff ff       	jmp    801060f4 <alltraps>

80106cfe <vector150>:
.globl vector150
vector150:
  pushl $0
80106cfe:	6a 00                	push   $0x0
  pushl $150
80106d00:	68 96 00 00 00       	push   $0x96
  jmp alltraps
80106d05:	e9 ea f3 ff ff       	jmp    801060f4 <alltraps>

80106d0a <vector151>:
.globl vector151
vector151:
  pushl $0
80106d0a:	6a 00                	push   $0x0
  pushl $151
80106d0c:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80106d11:	e9 de f3 ff ff       	jmp    801060f4 <alltraps>

80106d16 <vector152>:
.globl vector152
vector152:
  pushl $0
80106d16:	6a 00                	push   $0x0
  pushl $152
80106d18:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80106d1d:	e9 d2 f3 ff ff       	jmp    801060f4 <alltraps>

80106d22 <vector153>:
.globl vector153
vector153:
  pushl $0
80106d22:	6a 00                	push   $0x0
  pushl $153
80106d24:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80106d29:	e9 c6 f3 ff ff       	jmp    801060f4 <alltraps>

80106d2e <vector154>:
.globl vector154
vector154:
  pushl $0
80106d2e:	6a 00                	push   $0x0
  pushl $154
80106d30:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80106d35:	e9 ba f3 ff ff       	jmp    801060f4 <alltraps>

80106d3a <vector155>:
.globl vector155
vector155:
  pushl $0
80106d3a:	6a 00                	push   $0x0
  pushl $155
80106d3c:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80106d41:	e9 ae f3 ff ff       	jmp    801060f4 <alltraps>

80106d46 <vector156>:
.globl vector156
vector156:
  pushl $0
80106d46:	6a 00                	push   $0x0
  pushl $156
80106d48:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80106d4d:	e9 a2 f3 ff ff       	jmp    801060f4 <alltraps>

80106d52 <vector157>:
.globl vector157
vector157:
  pushl $0
80106d52:	6a 00                	push   $0x0
  pushl $157
80106d54:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80106d59:	e9 96 f3 ff ff       	jmp    801060f4 <alltraps>

80106d5e <vector158>:
.globl vector158
vector158:
  pushl $0
80106d5e:	6a 00                	push   $0x0
  pushl $158
80106d60:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80106d65:	e9 8a f3 ff ff       	jmp    801060f4 <alltraps>

80106d6a <vector159>:
.globl vector159
vector159:
  pushl $0
80106d6a:	6a 00                	push   $0x0
  pushl $159
80106d6c:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80106d71:	e9 7e f3 ff ff       	jmp    801060f4 <alltraps>

80106d76 <vector160>:
.globl vector160
vector160:
  pushl $0
80106d76:	6a 00                	push   $0x0
  pushl $160
80106d78:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80106d7d:	e9 72 f3 ff ff       	jmp    801060f4 <alltraps>

80106d82 <vector161>:
.globl vector161
vector161:
  pushl $0
80106d82:	6a 00                	push   $0x0
  pushl $161
80106d84:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80106d89:	e9 66 f3 ff ff       	jmp    801060f4 <alltraps>

80106d8e <vector162>:
.globl vector162
vector162:
  pushl $0
80106d8e:	6a 00                	push   $0x0
  pushl $162
80106d90:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80106d95:	e9 5a f3 ff ff       	jmp    801060f4 <alltraps>

80106d9a <vector163>:
.globl vector163
vector163:
  pushl $0
80106d9a:	6a 00                	push   $0x0
  pushl $163
80106d9c:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80106da1:	e9 4e f3 ff ff       	jmp    801060f4 <alltraps>

80106da6 <vector164>:
.globl vector164
vector164:
  pushl $0
80106da6:	6a 00                	push   $0x0
  pushl $164
80106da8:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80106dad:	e9 42 f3 ff ff       	jmp    801060f4 <alltraps>

80106db2 <vector165>:
.globl vector165
vector165:
  pushl $0
80106db2:	6a 00                	push   $0x0
  pushl $165
80106db4:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80106db9:	e9 36 f3 ff ff       	jmp    801060f4 <alltraps>

80106dbe <vector166>:
.globl vector166
vector166:
  pushl $0
80106dbe:	6a 00                	push   $0x0
  pushl $166
80106dc0:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80106dc5:	e9 2a f3 ff ff       	jmp    801060f4 <alltraps>

80106dca <vector167>:
.globl vector167
vector167:
  pushl $0
80106dca:	6a 00                	push   $0x0
  pushl $167
80106dcc:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80106dd1:	e9 1e f3 ff ff       	jmp    801060f4 <alltraps>

80106dd6 <vector168>:
.globl vector168
vector168:
  pushl $0
80106dd6:	6a 00                	push   $0x0
  pushl $168
80106dd8:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80106ddd:	e9 12 f3 ff ff       	jmp    801060f4 <alltraps>

80106de2 <vector169>:
.globl vector169
vector169:
  pushl $0
80106de2:	6a 00                	push   $0x0
  pushl $169
80106de4:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80106de9:	e9 06 f3 ff ff       	jmp    801060f4 <alltraps>

80106dee <vector170>:
.globl vector170
vector170:
  pushl $0
80106dee:	6a 00                	push   $0x0
  pushl $170
80106df0:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80106df5:	e9 fa f2 ff ff       	jmp    801060f4 <alltraps>

80106dfa <vector171>:
.globl vector171
vector171:
  pushl $0
80106dfa:	6a 00                	push   $0x0
  pushl $171
80106dfc:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80106e01:	e9 ee f2 ff ff       	jmp    801060f4 <alltraps>

80106e06 <vector172>:
.globl vector172
vector172:
  pushl $0
80106e06:	6a 00                	push   $0x0
  pushl $172
80106e08:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80106e0d:	e9 e2 f2 ff ff       	jmp    801060f4 <alltraps>

80106e12 <vector173>:
.globl vector173
vector173:
  pushl $0
80106e12:	6a 00                	push   $0x0
  pushl $173
80106e14:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80106e19:	e9 d6 f2 ff ff       	jmp    801060f4 <alltraps>

80106e1e <vector174>:
.globl vector174
vector174:
  pushl $0
80106e1e:	6a 00                	push   $0x0
  pushl $174
80106e20:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80106e25:	e9 ca f2 ff ff       	jmp    801060f4 <alltraps>

80106e2a <vector175>:
.globl vector175
vector175:
  pushl $0
80106e2a:	6a 00                	push   $0x0
  pushl $175
80106e2c:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80106e31:	e9 be f2 ff ff       	jmp    801060f4 <alltraps>

80106e36 <vector176>:
.globl vector176
vector176:
  pushl $0
80106e36:	6a 00                	push   $0x0
  pushl $176
80106e38:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80106e3d:	e9 b2 f2 ff ff       	jmp    801060f4 <alltraps>

80106e42 <vector177>:
.globl vector177
vector177:
  pushl $0
80106e42:	6a 00                	push   $0x0
  pushl $177
80106e44:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80106e49:	e9 a6 f2 ff ff       	jmp    801060f4 <alltraps>

80106e4e <vector178>:
.globl vector178
vector178:
  pushl $0
80106e4e:	6a 00                	push   $0x0
  pushl $178
80106e50:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80106e55:	e9 9a f2 ff ff       	jmp    801060f4 <alltraps>

80106e5a <vector179>:
.globl vector179
vector179:
  pushl $0
80106e5a:	6a 00                	push   $0x0
  pushl $179
80106e5c:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80106e61:	e9 8e f2 ff ff       	jmp    801060f4 <alltraps>

80106e66 <vector180>:
.globl vector180
vector180:
  pushl $0
80106e66:	6a 00                	push   $0x0
  pushl $180
80106e68:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80106e6d:	e9 82 f2 ff ff       	jmp    801060f4 <alltraps>

80106e72 <vector181>:
.globl vector181
vector181:
  pushl $0
80106e72:	6a 00                	push   $0x0
  pushl $181
80106e74:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80106e79:	e9 76 f2 ff ff       	jmp    801060f4 <alltraps>

80106e7e <vector182>:
.globl vector182
vector182:
  pushl $0
80106e7e:	6a 00                	push   $0x0
  pushl $182
80106e80:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80106e85:	e9 6a f2 ff ff       	jmp    801060f4 <alltraps>

80106e8a <vector183>:
.globl vector183
vector183:
  pushl $0
80106e8a:	6a 00                	push   $0x0
  pushl $183
80106e8c:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80106e91:	e9 5e f2 ff ff       	jmp    801060f4 <alltraps>

80106e96 <vector184>:
.globl vector184
vector184:
  pushl $0
80106e96:	6a 00                	push   $0x0
  pushl $184
80106e98:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80106e9d:	e9 52 f2 ff ff       	jmp    801060f4 <alltraps>

80106ea2 <vector185>:
.globl vector185
vector185:
  pushl $0
80106ea2:	6a 00                	push   $0x0
  pushl $185
80106ea4:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80106ea9:	e9 46 f2 ff ff       	jmp    801060f4 <alltraps>

80106eae <vector186>:
.globl vector186
vector186:
  pushl $0
80106eae:	6a 00                	push   $0x0
  pushl $186
80106eb0:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80106eb5:	e9 3a f2 ff ff       	jmp    801060f4 <alltraps>

80106eba <vector187>:
.globl vector187
vector187:
  pushl $0
80106eba:	6a 00                	push   $0x0
  pushl $187
80106ebc:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80106ec1:	e9 2e f2 ff ff       	jmp    801060f4 <alltraps>

80106ec6 <vector188>:
.globl vector188
vector188:
  pushl $0
80106ec6:	6a 00                	push   $0x0
  pushl $188
80106ec8:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80106ecd:	e9 22 f2 ff ff       	jmp    801060f4 <alltraps>

80106ed2 <vector189>:
.globl vector189
vector189:
  pushl $0
80106ed2:	6a 00                	push   $0x0
  pushl $189
80106ed4:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80106ed9:	e9 16 f2 ff ff       	jmp    801060f4 <alltraps>

80106ede <vector190>:
.globl vector190
vector190:
  pushl $0
80106ede:	6a 00                	push   $0x0
  pushl $190
80106ee0:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80106ee5:	e9 0a f2 ff ff       	jmp    801060f4 <alltraps>

80106eea <vector191>:
.globl vector191
vector191:
  pushl $0
80106eea:	6a 00                	push   $0x0
  pushl $191
80106eec:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80106ef1:	e9 fe f1 ff ff       	jmp    801060f4 <alltraps>

80106ef6 <vector192>:
.globl vector192
vector192:
  pushl $0
80106ef6:	6a 00                	push   $0x0
  pushl $192
80106ef8:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80106efd:	e9 f2 f1 ff ff       	jmp    801060f4 <alltraps>

80106f02 <vector193>:
.globl vector193
vector193:
  pushl $0
80106f02:	6a 00                	push   $0x0
  pushl $193
80106f04:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80106f09:	e9 e6 f1 ff ff       	jmp    801060f4 <alltraps>

80106f0e <vector194>:
.globl vector194
vector194:
  pushl $0
80106f0e:	6a 00                	push   $0x0
  pushl $194
80106f10:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80106f15:	e9 da f1 ff ff       	jmp    801060f4 <alltraps>

80106f1a <vector195>:
.globl vector195
vector195:
  pushl $0
80106f1a:	6a 00                	push   $0x0
  pushl $195
80106f1c:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80106f21:	e9 ce f1 ff ff       	jmp    801060f4 <alltraps>

80106f26 <vector196>:
.globl vector196
vector196:
  pushl $0
80106f26:	6a 00                	push   $0x0
  pushl $196
80106f28:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80106f2d:	e9 c2 f1 ff ff       	jmp    801060f4 <alltraps>

80106f32 <vector197>:
.globl vector197
vector197:
  pushl $0
80106f32:	6a 00                	push   $0x0
  pushl $197
80106f34:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80106f39:	e9 b6 f1 ff ff       	jmp    801060f4 <alltraps>

80106f3e <vector198>:
.globl vector198
vector198:
  pushl $0
80106f3e:	6a 00                	push   $0x0
  pushl $198
80106f40:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80106f45:	e9 aa f1 ff ff       	jmp    801060f4 <alltraps>

80106f4a <vector199>:
.globl vector199
vector199:
  pushl $0
80106f4a:	6a 00                	push   $0x0
  pushl $199
80106f4c:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80106f51:	e9 9e f1 ff ff       	jmp    801060f4 <alltraps>

80106f56 <vector200>:
.globl vector200
vector200:
  pushl $0
80106f56:	6a 00                	push   $0x0
  pushl $200
80106f58:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80106f5d:	e9 92 f1 ff ff       	jmp    801060f4 <alltraps>

80106f62 <vector201>:
.globl vector201
vector201:
  pushl $0
80106f62:	6a 00                	push   $0x0
  pushl $201
80106f64:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80106f69:	e9 86 f1 ff ff       	jmp    801060f4 <alltraps>

80106f6e <vector202>:
.globl vector202
vector202:
  pushl $0
80106f6e:	6a 00                	push   $0x0
  pushl $202
80106f70:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80106f75:	e9 7a f1 ff ff       	jmp    801060f4 <alltraps>

80106f7a <vector203>:
.globl vector203
vector203:
  pushl $0
80106f7a:	6a 00                	push   $0x0
  pushl $203
80106f7c:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80106f81:	e9 6e f1 ff ff       	jmp    801060f4 <alltraps>

80106f86 <vector204>:
.globl vector204
vector204:
  pushl $0
80106f86:	6a 00                	push   $0x0
  pushl $204
80106f88:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80106f8d:	e9 62 f1 ff ff       	jmp    801060f4 <alltraps>

80106f92 <vector205>:
.globl vector205
vector205:
  pushl $0
80106f92:	6a 00                	push   $0x0
  pushl $205
80106f94:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80106f99:	e9 56 f1 ff ff       	jmp    801060f4 <alltraps>

80106f9e <vector206>:
.globl vector206
vector206:
  pushl $0
80106f9e:	6a 00                	push   $0x0
  pushl $206
80106fa0:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80106fa5:	e9 4a f1 ff ff       	jmp    801060f4 <alltraps>

80106faa <vector207>:
.globl vector207
vector207:
  pushl $0
80106faa:	6a 00                	push   $0x0
  pushl $207
80106fac:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80106fb1:	e9 3e f1 ff ff       	jmp    801060f4 <alltraps>

80106fb6 <vector208>:
.globl vector208
vector208:
  pushl $0
80106fb6:	6a 00                	push   $0x0
  pushl $208
80106fb8:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80106fbd:	e9 32 f1 ff ff       	jmp    801060f4 <alltraps>

80106fc2 <vector209>:
.globl vector209
vector209:
  pushl $0
80106fc2:	6a 00                	push   $0x0
  pushl $209
80106fc4:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80106fc9:	e9 26 f1 ff ff       	jmp    801060f4 <alltraps>

80106fce <vector210>:
.globl vector210
vector210:
  pushl $0
80106fce:	6a 00                	push   $0x0
  pushl $210
80106fd0:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80106fd5:	e9 1a f1 ff ff       	jmp    801060f4 <alltraps>

80106fda <vector211>:
.globl vector211
vector211:
  pushl $0
80106fda:	6a 00                	push   $0x0
  pushl $211
80106fdc:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80106fe1:	e9 0e f1 ff ff       	jmp    801060f4 <alltraps>

80106fe6 <vector212>:
.globl vector212
vector212:
  pushl $0
80106fe6:	6a 00                	push   $0x0
  pushl $212
80106fe8:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80106fed:	e9 02 f1 ff ff       	jmp    801060f4 <alltraps>

80106ff2 <vector213>:
.globl vector213
vector213:
  pushl $0
80106ff2:	6a 00                	push   $0x0
  pushl $213
80106ff4:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80106ff9:	e9 f6 f0 ff ff       	jmp    801060f4 <alltraps>

80106ffe <vector214>:
.globl vector214
vector214:
  pushl $0
80106ffe:	6a 00                	push   $0x0
  pushl $214
80107000:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80107005:	e9 ea f0 ff ff       	jmp    801060f4 <alltraps>

8010700a <vector215>:
.globl vector215
vector215:
  pushl $0
8010700a:	6a 00                	push   $0x0
  pushl $215
8010700c:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80107011:	e9 de f0 ff ff       	jmp    801060f4 <alltraps>

80107016 <vector216>:
.globl vector216
vector216:
  pushl $0
80107016:	6a 00                	push   $0x0
  pushl $216
80107018:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
8010701d:	e9 d2 f0 ff ff       	jmp    801060f4 <alltraps>

80107022 <vector217>:
.globl vector217
vector217:
  pushl $0
80107022:	6a 00                	push   $0x0
  pushl $217
80107024:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80107029:	e9 c6 f0 ff ff       	jmp    801060f4 <alltraps>

8010702e <vector218>:
.globl vector218
vector218:
  pushl $0
8010702e:	6a 00                	push   $0x0
  pushl $218
80107030:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80107035:	e9 ba f0 ff ff       	jmp    801060f4 <alltraps>

8010703a <vector219>:
.globl vector219
vector219:
  pushl $0
8010703a:	6a 00                	push   $0x0
  pushl $219
8010703c:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80107041:	e9 ae f0 ff ff       	jmp    801060f4 <alltraps>

80107046 <vector220>:
.globl vector220
vector220:
  pushl $0
80107046:	6a 00                	push   $0x0
  pushl $220
80107048:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
8010704d:	e9 a2 f0 ff ff       	jmp    801060f4 <alltraps>

80107052 <vector221>:
.globl vector221
vector221:
  pushl $0
80107052:	6a 00                	push   $0x0
  pushl $221
80107054:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80107059:	e9 96 f0 ff ff       	jmp    801060f4 <alltraps>

8010705e <vector222>:
.globl vector222
vector222:
  pushl $0
8010705e:	6a 00                	push   $0x0
  pushl $222
80107060:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80107065:	e9 8a f0 ff ff       	jmp    801060f4 <alltraps>

8010706a <vector223>:
.globl vector223
vector223:
  pushl $0
8010706a:	6a 00                	push   $0x0
  pushl $223
8010706c:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80107071:	e9 7e f0 ff ff       	jmp    801060f4 <alltraps>

80107076 <vector224>:
.globl vector224
vector224:
  pushl $0
80107076:	6a 00                	push   $0x0
  pushl $224
80107078:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
8010707d:	e9 72 f0 ff ff       	jmp    801060f4 <alltraps>

80107082 <vector225>:
.globl vector225
vector225:
  pushl $0
80107082:	6a 00                	push   $0x0
  pushl $225
80107084:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80107089:	e9 66 f0 ff ff       	jmp    801060f4 <alltraps>

8010708e <vector226>:
.globl vector226
vector226:
  pushl $0
8010708e:	6a 00                	push   $0x0
  pushl $226
80107090:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80107095:	e9 5a f0 ff ff       	jmp    801060f4 <alltraps>

8010709a <vector227>:
.globl vector227
vector227:
  pushl $0
8010709a:	6a 00                	push   $0x0
  pushl $227
8010709c:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
801070a1:	e9 4e f0 ff ff       	jmp    801060f4 <alltraps>

801070a6 <vector228>:
.globl vector228
vector228:
  pushl $0
801070a6:	6a 00                	push   $0x0
  pushl $228
801070a8:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
801070ad:	e9 42 f0 ff ff       	jmp    801060f4 <alltraps>

801070b2 <vector229>:
.globl vector229
vector229:
  pushl $0
801070b2:	6a 00                	push   $0x0
  pushl $229
801070b4:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
801070b9:	e9 36 f0 ff ff       	jmp    801060f4 <alltraps>

801070be <vector230>:
.globl vector230
vector230:
  pushl $0
801070be:	6a 00                	push   $0x0
  pushl $230
801070c0:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
801070c5:	e9 2a f0 ff ff       	jmp    801060f4 <alltraps>

801070ca <vector231>:
.globl vector231
vector231:
  pushl $0
801070ca:	6a 00                	push   $0x0
  pushl $231
801070cc:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
801070d1:	e9 1e f0 ff ff       	jmp    801060f4 <alltraps>

801070d6 <vector232>:
.globl vector232
vector232:
  pushl $0
801070d6:	6a 00                	push   $0x0
  pushl $232
801070d8:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
801070dd:	e9 12 f0 ff ff       	jmp    801060f4 <alltraps>

801070e2 <vector233>:
.globl vector233
vector233:
  pushl $0
801070e2:	6a 00                	push   $0x0
  pushl $233
801070e4:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
801070e9:	e9 06 f0 ff ff       	jmp    801060f4 <alltraps>

801070ee <vector234>:
.globl vector234
vector234:
  pushl $0
801070ee:	6a 00                	push   $0x0
  pushl $234
801070f0:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
801070f5:	e9 fa ef ff ff       	jmp    801060f4 <alltraps>

801070fa <vector235>:
.globl vector235
vector235:
  pushl $0
801070fa:	6a 00                	push   $0x0
  pushl $235
801070fc:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80107101:	e9 ee ef ff ff       	jmp    801060f4 <alltraps>

80107106 <vector236>:
.globl vector236
vector236:
  pushl $0
80107106:	6a 00                	push   $0x0
  pushl $236
80107108:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
8010710d:	e9 e2 ef ff ff       	jmp    801060f4 <alltraps>

80107112 <vector237>:
.globl vector237
vector237:
  pushl $0
80107112:	6a 00                	push   $0x0
  pushl $237
80107114:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80107119:	e9 d6 ef ff ff       	jmp    801060f4 <alltraps>

8010711e <vector238>:
.globl vector238
vector238:
  pushl $0
8010711e:	6a 00                	push   $0x0
  pushl $238
80107120:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80107125:	e9 ca ef ff ff       	jmp    801060f4 <alltraps>

8010712a <vector239>:
.globl vector239
vector239:
  pushl $0
8010712a:	6a 00                	push   $0x0
  pushl $239
8010712c:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80107131:	e9 be ef ff ff       	jmp    801060f4 <alltraps>

80107136 <vector240>:
.globl vector240
vector240:
  pushl $0
80107136:	6a 00                	push   $0x0
  pushl $240
80107138:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
8010713d:	e9 b2 ef ff ff       	jmp    801060f4 <alltraps>

80107142 <vector241>:
.globl vector241
vector241:
  pushl $0
80107142:	6a 00                	push   $0x0
  pushl $241
80107144:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80107149:	e9 a6 ef ff ff       	jmp    801060f4 <alltraps>

8010714e <vector242>:
.globl vector242
vector242:
  pushl $0
8010714e:	6a 00                	push   $0x0
  pushl $242
80107150:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80107155:	e9 9a ef ff ff       	jmp    801060f4 <alltraps>

8010715a <vector243>:
.globl vector243
vector243:
  pushl $0
8010715a:	6a 00                	push   $0x0
  pushl $243
8010715c:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80107161:	e9 8e ef ff ff       	jmp    801060f4 <alltraps>

80107166 <vector244>:
.globl vector244
vector244:
  pushl $0
80107166:	6a 00                	push   $0x0
  pushl $244
80107168:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
8010716d:	e9 82 ef ff ff       	jmp    801060f4 <alltraps>

80107172 <vector245>:
.globl vector245
vector245:
  pushl $0
80107172:	6a 00                	push   $0x0
  pushl $245
80107174:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80107179:	e9 76 ef ff ff       	jmp    801060f4 <alltraps>

8010717e <vector246>:
.globl vector246
vector246:
  pushl $0
8010717e:	6a 00                	push   $0x0
  pushl $246
80107180:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80107185:	e9 6a ef ff ff       	jmp    801060f4 <alltraps>

8010718a <vector247>:
.globl vector247
vector247:
  pushl $0
8010718a:	6a 00                	push   $0x0
  pushl $247
8010718c:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80107191:	e9 5e ef ff ff       	jmp    801060f4 <alltraps>

80107196 <vector248>:
.globl vector248
vector248:
  pushl $0
80107196:	6a 00                	push   $0x0
  pushl $248
80107198:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
8010719d:	e9 52 ef ff ff       	jmp    801060f4 <alltraps>

801071a2 <vector249>:
.globl vector249
vector249:
  pushl $0
801071a2:	6a 00                	push   $0x0
  pushl $249
801071a4:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
801071a9:	e9 46 ef ff ff       	jmp    801060f4 <alltraps>

801071ae <vector250>:
.globl vector250
vector250:
  pushl $0
801071ae:	6a 00                	push   $0x0
  pushl $250
801071b0:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
801071b5:	e9 3a ef ff ff       	jmp    801060f4 <alltraps>

801071ba <vector251>:
.globl vector251
vector251:
  pushl $0
801071ba:	6a 00                	push   $0x0
  pushl $251
801071bc:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
801071c1:	e9 2e ef ff ff       	jmp    801060f4 <alltraps>

801071c6 <vector252>:
.globl vector252
vector252:
  pushl $0
801071c6:	6a 00                	push   $0x0
  pushl $252
801071c8:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
801071cd:	e9 22 ef ff ff       	jmp    801060f4 <alltraps>

801071d2 <vector253>:
.globl vector253
vector253:
  pushl $0
801071d2:	6a 00                	push   $0x0
  pushl $253
801071d4:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
801071d9:	e9 16 ef ff ff       	jmp    801060f4 <alltraps>

801071de <vector254>:
.globl vector254
vector254:
  pushl $0
801071de:	6a 00                	push   $0x0
  pushl $254
801071e0:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
801071e5:	e9 0a ef ff ff       	jmp    801060f4 <alltraps>

801071ea <vector255>:
.globl vector255
vector255:
  pushl $0
801071ea:	6a 00                	push   $0x0
  pushl $255
801071ec:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
801071f1:	e9 fe ee ff ff       	jmp    801060f4 <alltraps>
	...

801071f8 <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
801071f8:	55                   	push   %ebp
801071f9:	89 e5                	mov    %esp,%ebp
801071fb:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
801071fe:	8b 45 0c             	mov    0xc(%ebp),%eax
80107201:	83 e8 01             	sub    $0x1,%eax
80107204:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80107208:	8b 45 08             	mov    0x8(%ebp),%eax
8010720b:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
8010720f:	8b 45 08             	mov    0x8(%ebp),%eax
80107212:	c1 e8 10             	shr    $0x10,%eax
80107215:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
80107219:	8d 45 fa             	lea    -0x6(%ebp),%eax
8010721c:	0f 01 10             	lgdtl  (%eax)
}
8010721f:	c9                   	leave  
80107220:	c3                   	ret    

80107221 <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
80107221:	55                   	push   %ebp
80107222:	89 e5                	mov    %esp,%ebp
80107224:	83 ec 04             	sub    $0x4,%esp
80107227:	8b 45 08             	mov    0x8(%ebp),%eax
8010722a:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
8010722e:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80107232:	0f 00 d8             	ltr    %ax
}
80107235:	c9                   	leave  
80107236:	c3                   	ret    

80107237 <loadgs>:
  return eflags;
}

static inline void
loadgs(ushort v)
{
80107237:	55                   	push   %ebp
80107238:	89 e5                	mov    %esp,%ebp
8010723a:	83 ec 04             	sub    $0x4,%esp
8010723d:	8b 45 08             	mov    0x8(%ebp),%eax
80107240:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("movw %0, %%gs" : : "r" (v));
80107244:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80107248:	8e e8                	mov    %eax,%gs
}
8010724a:	c9                   	leave  
8010724b:	c3                   	ret    

8010724c <lcr3>:
  return val;
}

static inline void
lcr3(uint val) 
{
8010724c:	55                   	push   %ebp
8010724d:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
8010724f:	8b 45 08             	mov    0x8(%ebp),%eax
80107252:	0f 22 d8             	mov    %eax,%cr3
}
80107255:	5d                   	pop    %ebp
80107256:	c3                   	ret    

80107257 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80107257:	55                   	push   %ebp
80107258:	89 e5                	mov    %esp,%ebp
8010725a:	8b 45 08             	mov    0x8(%ebp),%eax
8010725d:	05 00 00 00 80       	add    $0x80000000,%eax
80107262:	5d                   	pop    %ebp
80107263:	c3                   	ret    

80107264 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80107264:	55                   	push   %ebp
80107265:	89 e5                	mov    %esp,%ebp
80107267:	8b 45 08             	mov    0x8(%ebp),%eax
8010726a:	05 00 00 00 80       	add    $0x80000000,%eax
8010726f:	5d                   	pop    %ebp
80107270:	c3                   	ret    

80107271 <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
80107271:	55                   	push   %ebp
80107272:	89 e5                	mov    %esp,%ebp
80107274:	53                   	push   %ebx
80107275:	83 ec 24             	sub    $0x24,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
80107278:	e8 08 bc ff ff       	call   80102e85 <cpunum>
8010727d:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80107283:	05 20 f9 10 80       	add    $0x8010f920,%eax
80107288:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
8010728b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010728e:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
80107294:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107297:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
8010729d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801072a0:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
801072a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801072a7:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801072ab:	83 e2 f0             	and    $0xfffffff0,%edx
801072ae:	83 ca 0a             	or     $0xa,%edx
801072b1:	88 50 7d             	mov    %dl,0x7d(%eax)
801072b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801072b7:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801072bb:	83 ca 10             	or     $0x10,%edx
801072be:	88 50 7d             	mov    %dl,0x7d(%eax)
801072c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801072c4:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801072c8:	83 e2 9f             	and    $0xffffff9f,%edx
801072cb:	88 50 7d             	mov    %dl,0x7d(%eax)
801072ce:	8b 45 f4             	mov    -0xc(%ebp),%eax
801072d1:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801072d5:	83 ca 80             	or     $0xffffff80,%edx
801072d8:	88 50 7d             	mov    %dl,0x7d(%eax)
801072db:	8b 45 f4             	mov    -0xc(%ebp),%eax
801072de:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801072e2:	83 ca 0f             	or     $0xf,%edx
801072e5:	88 50 7e             	mov    %dl,0x7e(%eax)
801072e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801072eb:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801072ef:	83 e2 ef             	and    $0xffffffef,%edx
801072f2:	88 50 7e             	mov    %dl,0x7e(%eax)
801072f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801072f8:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801072fc:	83 e2 df             	and    $0xffffffdf,%edx
801072ff:	88 50 7e             	mov    %dl,0x7e(%eax)
80107302:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107305:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107309:	83 ca 40             	or     $0x40,%edx
8010730c:	88 50 7e             	mov    %dl,0x7e(%eax)
8010730f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107312:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107316:	83 ca 80             	or     $0xffffff80,%edx
80107319:	88 50 7e             	mov    %dl,0x7e(%eax)
8010731c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010731f:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80107323:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107326:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
8010732d:	ff ff 
8010732f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107332:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
80107339:	00 00 
8010733b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010733e:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
80107345:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107348:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
8010734f:	83 e2 f0             	and    $0xfffffff0,%edx
80107352:	83 ca 02             	or     $0x2,%edx
80107355:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
8010735b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010735e:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107365:	83 ca 10             	or     $0x10,%edx
80107368:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
8010736e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107371:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107378:	83 e2 9f             	and    $0xffffff9f,%edx
8010737b:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107381:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107384:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
8010738b:	83 ca 80             	or     $0xffffff80,%edx
8010738e:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107394:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107397:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010739e:	83 ca 0f             	or     $0xf,%edx
801073a1:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801073a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801073aa:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801073b1:	83 e2 ef             	and    $0xffffffef,%edx
801073b4:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801073ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
801073bd:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801073c4:	83 e2 df             	and    $0xffffffdf,%edx
801073c7:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801073cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801073d0:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801073d7:	83 ca 40             	or     $0x40,%edx
801073da:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801073e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801073e3:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801073ea:	83 ca 80             	or     $0xffffff80,%edx
801073ed:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801073f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801073f6:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
801073fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107400:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
80107407:	ff ff 
80107409:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010740c:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
80107413:	00 00 
80107415:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107418:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
8010741f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107422:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107429:	83 e2 f0             	and    $0xfffffff0,%edx
8010742c:	83 ca 0a             	or     $0xa,%edx
8010742f:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107435:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107438:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
8010743f:	83 ca 10             	or     $0x10,%edx
80107442:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107448:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010744b:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107452:	83 ca 60             	or     $0x60,%edx
80107455:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
8010745b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010745e:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107465:	83 ca 80             	or     $0xffffff80,%edx
80107468:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
8010746e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107471:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107478:	83 ca 0f             	or     $0xf,%edx
8010747b:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107481:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107484:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
8010748b:	83 e2 ef             	and    $0xffffffef,%edx
8010748e:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107494:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107497:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
8010749e:	83 e2 df             	and    $0xffffffdf,%edx
801074a1:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801074a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074aa:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801074b1:	83 ca 40             	or     $0x40,%edx
801074b4:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801074ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074bd:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801074c4:	83 ca 80             	or     $0xffffff80,%edx
801074c7:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801074cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074d0:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
801074d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074da:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
801074e1:	ff ff 
801074e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074e6:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
801074ed:	00 00 
801074ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074f2:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
801074f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074fc:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107503:	83 e2 f0             	and    $0xfffffff0,%edx
80107506:	83 ca 02             	or     $0x2,%edx
80107509:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
8010750f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107512:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107519:	83 ca 10             	or     $0x10,%edx
8010751c:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107522:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107525:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
8010752c:	83 ca 60             	or     $0x60,%edx
8010752f:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107535:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107538:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
8010753f:	83 ca 80             	or     $0xffffff80,%edx
80107542:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107548:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010754b:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107552:	83 ca 0f             	or     $0xf,%edx
80107555:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
8010755b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010755e:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107565:	83 e2 ef             	and    $0xffffffef,%edx
80107568:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
8010756e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107571:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107578:	83 e2 df             	and    $0xffffffdf,%edx
8010757b:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107581:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107584:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
8010758b:	83 ca 40             	or     $0x40,%edx
8010758e:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107594:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107597:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
8010759e:	83 ca 80             	or     $0xffffff80,%edx
801075a1:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801075a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075aa:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
801075b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075b4:	05 b4 00 00 00       	add    $0xb4,%eax
801075b9:	89 c3                	mov    %eax,%ebx
801075bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075be:	05 b4 00 00 00       	add    $0xb4,%eax
801075c3:	c1 e8 10             	shr    $0x10,%eax
801075c6:	89 c1                	mov    %eax,%ecx
801075c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075cb:	05 b4 00 00 00       	add    $0xb4,%eax
801075d0:	c1 e8 18             	shr    $0x18,%eax
801075d3:	89 c2                	mov    %eax,%edx
801075d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075d8:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
801075df:	00 00 
801075e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075e4:	66 89 98 8a 00 00 00 	mov    %bx,0x8a(%eax)
801075eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075ee:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
801075f4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075f7:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
801075fe:	83 e1 f0             	and    $0xfffffff0,%ecx
80107601:	83 c9 02             	or     $0x2,%ecx
80107604:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
8010760a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010760d:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107614:	83 c9 10             	or     $0x10,%ecx
80107617:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
8010761d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107620:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107627:	83 e1 9f             	and    $0xffffff9f,%ecx
8010762a:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107630:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107633:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
8010763a:	83 c9 80             	or     $0xffffff80,%ecx
8010763d:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107643:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107646:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
8010764d:	83 e1 f0             	and    $0xfffffff0,%ecx
80107650:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107656:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107659:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107660:	83 e1 ef             	and    $0xffffffef,%ecx
80107663:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107669:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010766c:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107673:	83 e1 df             	and    $0xffffffdf,%ecx
80107676:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
8010767c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010767f:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107686:	83 c9 40             	or     $0x40,%ecx
80107689:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
8010768f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107692:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107699:	83 c9 80             	or     $0xffffff80,%ecx
8010769c:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801076a2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076a5:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)

  lgdt(c->gdt, sizeof(c->gdt));
801076ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076ae:	83 c0 70             	add    $0x70,%eax
801076b1:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
801076b8:	00 
801076b9:	89 04 24             	mov    %eax,(%esp)
801076bc:	e8 37 fb ff ff       	call   801071f8 <lgdt>
  loadgs(SEG_KCPU << 3);
801076c1:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
801076c8:	e8 6a fb ff ff       	call   80107237 <loadgs>
  
  // Initialize cpu-local storage.
  cpu = c;
801076cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076d0:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
801076d6:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
801076dd:	00 00 00 00 
}
801076e1:	83 c4 24             	add    $0x24,%esp
801076e4:	5b                   	pop    %ebx
801076e5:	5d                   	pop    %ebp
801076e6:	c3                   	ret    

801076e7 <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
801076e7:	55                   	push   %ebp
801076e8:	89 e5                	mov    %esp,%ebp
801076ea:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
801076ed:	8b 45 0c             	mov    0xc(%ebp),%eax
801076f0:	c1 e8 16             	shr    $0x16,%eax
801076f3:	c1 e0 02             	shl    $0x2,%eax
801076f6:	03 45 08             	add    0x8(%ebp),%eax
801076f9:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
801076fc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801076ff:	8b 00                	mov    (%eax),%eax
80107701:	83 e0 01             	and    $0x1,%eax
80107704:	84 c0                	test   %al,%al
80107706:	74 17                	je     8010771f <walkpgdir+0x38>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
80107708:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010770b:	8b 00                	mov    (%eax),%eax
8010770d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107712:	89 04 24             	mov    %eax,(%esp)
80107715:	e8 4a fb ff ff       	call   80107264 <p2v>
8010771a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010771d:	eb 4b                	jmp    8010776a <walkpgdir+0x83>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
8010771f:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80107723:	74 0e                	je     80107733 <walkpgdir+0x4c>
80107725:	e8 cd b3 ff ff       	call   80102af7 <kalloc>
8010772a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010772d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80107731:	75 07                	jne    8010773a <walkpgdir+0x53>
      return 0;
80107733:	b8 00 00 00 00       	mov    $0x0,%eax
80107738:	eb 41                	jmp    8010777b <walkpgdir+0x94>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
8010773a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107741:	00 
80107742:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107749:	00 
8010774a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010774d:	89 04 24             	mov    %eax,(%esp)
80107750:	e8 bd d5 ff ff       	call   80104d12 <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
80107755:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107758:	89 04 24             	mov    %eax,(%esp)
8010775b:	e8 f7 fa ff ff       	call   80107257 <v2p>
80107760:	89 c2                	mov    %eax,%edx
80107762:	83 ca 07             	or     $0x7,%edx
80107765:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107768:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
8010776a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010776d:	c1 e8 0c             	shr    $0xc,%eax
80107770:	25 ff 03 00 00       	and    $0x3ff,%eax
80107775:	c1 e0 02             	shl    $0x2,%eax
80107778:	03 45 f4             	add    -0xc(%ebp),%eax
}
8010777b:	c9                   	leave  
8010777c:	c3                   	ret    

8010777d <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
8010777d:	55                   	push   %ebp
8010777e:	89 e5                	mov    %esp,%ebp
80107780:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
80107783:	8b 45 0c             	mov    0xc(%ebp),%eax
80107786:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010778b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
8010778e:	8b 45 0c             	mov    0xc(%ebp),%eax
80107791:	03 45 10             	add    0x10(%ebp),%eax
80107794:	83 e8 01             	sub    $0x1,%eax
80107797:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010779c:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
8010779f:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
801077a6:	00 
801077a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077aa:	89 44 24 04          	mov    %eax,0x4(%esp)
801077ae:	8b 45 08             	mov    0x8(%ebp),%eax
801077b1:	89 04 24             	mov    %eax,(%esp)
801077b4:	e8 2e ff ff ff       	call   801076e7 <walkpgdir>
801077b9:	89 45 ec             	mov    %eax,-0x14(%ebp)
801077bc:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801077c0:	75 07                	jne    801077c9 <mappages+0x4c>
      return -1;
801077c2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801077c7:	eb 46                	jmp    8010780f <mappages+0x92>
    if(*pte & PTE_P)
801077c9:	8b 45 ec             	mov    -0x14(%ebp),%eax
801077cc:	8b 00                	mov    (%eax),%eax
801077ce:	83 e0 01             	and    $0x1,%eax
801077d1:	84 c0                	test   %al,%al
801077d3:	74 0c                	je     801077e1 <mappages+0x64>
      panic("remap");
801077d5:	c7 04 24 f8 85 10 80 	movl   $0x801085f8,(%esp)
801077dc:	e8 5c 8d ff ff       	call   8010053d <panic>
    *pte = pa | perm | PTE_P;
801077e1:	8b 45 18             	mov    0x18(%ebp),%eax
801077e4:	0b 45 14             	or     0x14(%ebp),%eax
801077e7:	89 c2                	mov    %eax,%edx
801077e9:	83 ca 01             	or     $0x1,%edx
801077ec:	8b 45 ec             	mov    -0x14(%ebp),%eax
801077ef:	89 10                	mov    %edx,(%eax)
    if(a == last)
801077f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077f4:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801077f7:	74 10                	je     80107809 <mappages+0x8c>
      break;
    a += PGSIZE;
801077f9:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
80107800:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
80107807:	eb 96                	jmp    8010779f <mappages+0x22>
      return -1;
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
80107809:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
8010780a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010780f:	c9                   	leave  
80107810:	c3                   	ret    

80107811 <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm(void)
{
80107811:	55                   	push   %ebp
80107812:	89 e5                	mov    %esp,%ebp
80107814:	53                   	push   %ebx
80107815:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
80107818:	e8 da b2 ff ff       	call   80102af7 <kalloc>
8010781d:	89 45 f0             	mov    %eax,-0x10(%ebp)
80107820:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107824:	75 0a                	jne    80107830 <setupkvm+0x1f>
    return 0;
80107826:	b8 00 00 00 00       	mov    $0x0,%eax
8010782b:	e9 98 00 00 00       	jmp    801078c8 <setupkvm+0xb7>
  memset(pgdir, 0, PGSIZE);
80107830:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107837:	00 
80107838:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010783f:	00 
80107840:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107843:	89 04 24             	mov    %eax,(%esp)
80107846:	e8 c7 d4 ff ff       	call   80104d12 <memset>
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
8010784b:	c7 04 24 00 00 00 0e 	movl   $0xe000000,(%esp)
80107852:	e8 0d fa ff ff       	call   80107264 <p2v>
80107857:	3d 00 00 00 fe       	cmp    $0xfe000000,%eax
8010785c:	76 0c                	jbe    8010786a <setupkvm+0x59>
    panic("PHYSTOP too high");
8010785e:	c7 04 24 fe 85 10 80 	movl   $0x801085fe,(%esp)
80107865:	e8 d3 8c ff ff       	call   8010053d <panic>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
8010786a:	c7 45 f4 a0 b4 10 80 	movl   $0x8010b4a0,-0xc(%ebp)
80107871:	eb 49                	jmp    801078bc <setupkvm+0xab>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
80107873:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80107876:	8b 48 0c             	mov    0xc(%eax),%ecx
                (uint)k->phys_start, k->perm) < 0)
80107879:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
8010787c:	8b 50 04             	mov    0x4(%eax),%edx
8010787f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107882:	8b 58 08             	mov    0x8(%eax),%ebx
80107885:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107888:	8b 40 04             	mov    0x4(%eax),%eax
8010788b:	29 c3                	sub    %eax,%ebx
8010788d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107890:	8b 00                	mov    (%eax),%eax
80107892:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80107896:	89 54 24 0c          	mov    %edx,0xc(%esp)
8010789a:	89 5c 24 08          	mov    %ebx,0x8(%esp)
8010789e:	89 44 24 04          	mov    %eax,0x4(%esp)
801078a2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801078a5:	89 04 24             	mov    %eax,(%esp)
801078a8:	e8 d0 fe ff ff       	call   8010777d <mappages>
801078ad:	85 c0                	test   %eax,%eax
801078af:	79 07                	jns    801078b8 <setupkvm+0xa7>
                (uint)k->phys_start, k->perm) < 0)
      return 0;
801078b1:	b8 00 00 00 00       	mov    $0x0,%eax
801078b6:	eb 10                	jmp    801078c8 <setupkvm+0xb7>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
801078b8:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
801078bc:	81 7d f4 e0 b4 10 80 	cmpl   $0x8010b4e0,-0xc(%ebp)
801078c3:	72 ae                	jb     80107873 <setupkvm+0x62>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
      return 0;
  return pgdir;
801078c5:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
801078c8:	83 c4 34             	add    $0x34,%esp
801078cb:	5b                   	pop    %ebx
801078cc:	5d                   	pop    %ebp
801078cd:	c3                   	ret    

801078ce <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
void
kvmalloc(void)
{
801078ce:	55                   	push   %ebp
801078cf:	89 e5                	mov    %esp,%ebp
801078d1:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
801078d4:	e8 38 ff ff ff       	call   80107811 <setupkvm>
801078d9:	a3 f8 26 11 80       	mov    %eax,0x801126f8
  switchkvm();
801078de:	e8 02 00 00 00       	call   801078e5 <switchkvm>
}
801078e3:	c9                   	leave  
801078e4:	c3                   	ret    

801078e5 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
801078e5:	55                   	push   %ebp
801078e6:	89 e5                	mov    %esp,%ebp
801078e8:	83 ec 04             	sub    $0x4,%esp
  lcr3(v2p(kpgdir));   // switch to the kernel page table
801078eb:	a1 f8 26 11 80       	mov    0x801126f8,%eax
801078f0:	89 04 24             	mov    %eax,(%esp)
801078f3:	e8 5f f9 ff ff       	call   80107257 <v2p>
801078f8:	89 04 24             	mov    %eax,(%esp)
801078fb:	e8 4c f9 ff ff       	call   8010724c <lcr3>
}
80107900:	c9                   	leave  
80107901:	c3                   	ret    

80107902 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80107902:	55                   	push   %ebp
80107903:	89 e5                	mov    %esp,%ebp
80107905:	53                   	push   %ebx
80107906:	83 ec 14             	sub    $0x14,%esp
  pushcli();
80107909:	e8 fd d2 ff ff       	call   80104c0b <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
8010790e:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107914:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
8010791b:	83 c2 08             	add    $0x8,%edx
8010791e:	89 d3                	mov    %edx,%ebx
80107920:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107927:	83 c2 08             	add    $0x8,%edx
8010792a:	c1 ea 10             	shr    $0x10,%edx
8010792d:	89 d1                	mov    %edx,%ecx
8010792f:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107936:	83 c2 08             	add    $0x8,%edx
80107939:	c1 ea 18             	shr    $0x18,%edx
8010793c:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
80107943:	67 00 
80107945:	66 89 98 a2 00 00 00 	mov    %bx,0xa2(%eax)
8010794c:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
80107952:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107959:	83 e1 f0             	and    $0xfffffff0,%ecx
8010795c:	83 c9 09             	or     $0x9,%ecx
8010795f:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107965:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
8010796c:	83 c9 10             	or     $0x10,%ecx
8010796f:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107975:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
8010797c:	83 e1 9f             	and    $0xffffff9f,%ecx
8010797f:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107985:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
8010798c:	83 c9 80             	or     $0xffffff80,%ecx
8010798f:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107995:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
8010799c:	83 e1 f0             	and    $0xfffffff0,%ecx
8010799f:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
801079a5:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
801079ac:	83 e1 ef             	and    $0xffffffef,%ecx
801079af:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
801079b5:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
801079bc:	83 e1 df             	and    $0xffffffdf,%ecx
801079bf:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
801079c5:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
801079cc:	83 c9 40             	or     $0x40,%ecx
801079cf:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
801079d5:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
801079dc:	83 e1 7f             	and    $0x7f,%ecx
801079df:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
801079e5:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  cpu->gdt[SEG_TSS].s = 0;
801079eb:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801079f1:	0f b6 90 a5 00 00 00 	movzbl 0xa5(%eax),%edx
801079f8:	83 e2 ef             	and    $0xffffffef,%edx
801079fb:	88 90 a5 00 00 00    	mov    %dl,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
80107a01:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107a07:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
80107a0d:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107a13:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80107a1a:	8b 52 08             	mov    0x8(%edx),%edx
80107a1d:	81 c2 00 10 00 00    	add    $0x1000,%edx
80107a23:	89 50 0c             	mov    %edx,0xc(%eax)
  ltr(SEG_TSS << 3);
80107a26:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
80107a2d:	e8 ef f7 ff ff       	call   80107221 <ltr>
  if(p->pgdir == 0)
80107a32:	8b 45 08             	mov    0x8(%ebp),%eax
80107a35:	8b 40 04             	mov    0x4(%eax),%eax
80107a38:	85 c0                	test   %eax,%eax
80107a3a:	75 0c                	jne    80107a48 <switchuvm+0x146>
    panic("switchuvm: no pgdir");
80107a3c:	c7 04 24 0f 86 10 80 	movl   $0x8010860f,(%esp)
80107a43:	e8 f5 8a ff ff       	call   8010053d <panic>
  lcr3(v2p(p->pgdir));  // switch to new address space
80107a48:	8b 45 08             	mov    0x8(%ebp),%eax
80107a4b:	8b 40 04             	mov    0x4(%eax),%eax
80107a4e:	89 04 24             	mov    %eax,(%esp)
80107a51:	e8 01 f8 ff ff       	call   80107257 <v2p>
80107a56:	89 04 24             	mov    %eax,(%esp)
80107a59:	e8 ee f7 ff ff       	call   8010724c <lcr3>
  popcli();
80107a5e:	e8 f0 d1 ff ff       	call   80104c53 <popcli>
}
80107a63:	83 c4 14             	add    $0x14,%esp
80107a66:	5b                   	pop    %ebx
80107a67:	5d                   	pop    %ebp
80107a68:	c3                   	ret    

80107a69 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
80107a69:	55                   	push   %ebp
80107a6a:	89 e5                	mov    %esp,%ebp
80107a6c:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  
  if(sz >= PGSIZE)
80107a6f:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
80107a76:	76 0c                	jbe    80107a84 <inituvm+0x1b>
    panic("inituvm: more than a page");
80107a78:	c7 04 24 23 86 10 80 	movl   $0x80108623,(%esp)
80107a7f:	e8 b9 8a ff ff       	call   8010053d <panic>
  mem = kalloc();
80107a84:	e8 6e b0 ff ff       	call   80102af7 <kalloc>
80107a89:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
80107a8c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107a93:	00 
80107a94:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107a9b:	00 
80107a9c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a9f:	89 04 24             	mov    %eax,(%esp)
80107aa2:	e8 6b d2 ff ff       	call   80104d12 <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
80107aa7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107aaa:	89 04 24             	mov    %eax,(%esp)
80107aad:	e8 a5 f7 ff ff       	call   80107257 <v2p>
80107ab2:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80107ab9:	00 
80107aba:	89 44 24 0c          	mov    %eax,0xc(%esp)
80107abe:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107ac5:	00 
80107ac6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107acd:	00 
80107ace:	8b 45 08             	mov    0x8(%ebp),%eax
80107ad1:	89 04 24             	mov    %eax,(%esp)
80107ad4:	e8 a4 fc ff ff       	call   8010777d <mappages>
  memmove(mem, init, sz);
80107ad9:	8b 45 10             	mov    0x10(%ebp),%eax
80107adc:	89 44 24 08          	mov    %eax,0x8(%esp)
80107ae0:	8b 45 0c             	mov    0xc(%ebp),%eax
80107ae3:	89 44 24 04          	mov    %eax,0x4(%esp)
80107ae7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107aea:	89 04 24             	mov    %eax,(%esp)
80107aed:	e8 f3 d2 ff ff       	call   80104de5 <memmove>
}
80107af2:	c9                   	leave  
80107af3:	c3                   	ret    

80107af4 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80107af4:	55                   	push   %ebp
80107af5:	89 e5                	mov    %esp,%ebp
80107af7:	53                   	push   %ebx
80107af8:	83 ec 24             	sub    $0x24,%esp
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
80107afb:	8b 45 0c             	mov    0xc(%ebp),%eax
80107afe:	25 ff 0f 00 00       	and    $0xfff,%eax
80107b03:	85 c0                	test   %eax,%eax
80107b05:	74 0c                	je     80107b13 <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
80107b07:	c7 04 24 40 86 10 80 	movl   $0x80108640,(%esp)
80107b0e:	e8 2a 8a ff ff       	call   8010053d <panic>
  for(i = 0; i < sz; i += PGSIZE){
80107b13:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80107b1a:	e9 ad 00 00 00       	jmp    80107bcc <loaduvm+0xd8>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
80107b1f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b22:	8b 55 0c             	mov    0xc(%ebp),%edx
80107b25:	01 d0                	add    %edx,%eax
80107b27:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80107b2e:	00 
80107b2f:	89 44 24 04          	mov    %eax,0x4(%esp)
80107b33:	8b 45 08             	mov    0x8(%ebp),%eax
80107b36:	89 04 24             	mov    %eax,(%esp)
80107b39:	e8 a9 fb ff ff       	call   801076e7 <walkpgdir>
80107b3e:	89 45 ec             	mov    %eax,-0x14(%ebp)
80107b41:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80107b45:	75 0c                	jne    80107b53 <loaduvm+0x5f>
      panic("loaduvm: address should exist");
80107b47:	c7 04 24 63 86 10 80 	movl   $0x80108663,(%esp)
80107b4e:	e8 ea 89 ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
80107b53:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107b56:	8b 00                	mov    (%eax),%eax
80107b58:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107b5d:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
80107b60:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b63:	8b 55 18             	mov    0x18(%ebp),%edx
80107b66:	89 d1                	mov    %edx,%ecx
80107b68:	29 c1                	sub    %eax,%ecx
80107b6a:	89 c8                	mov    %ecx,%eax
80107b6c:	3d ff 0f 00 00       	cmp    $0xfff,%eax
80107b71:	77 11                	ja     80107b84 <loaduvm+0x90>
      n = sz - i;
80107b73:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b76:	8b 55 18             	mov    0x18(%ebp),%edx
80107b79:	89 d1                	mov    %edx,%ecx
80107b7b:	29 c1                	sub    %eax,%ecx
80107b7d:	89 c8                	mov    %ecx,%eax
80107b7f:	89 45 f0             	mov    %eax,-0x10(%ebp)
80107b82:	eb 07                	jmp    80107b8b <loaduvm+0x97>
    else
      n = PGSIZE;
80107b84:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
80107b8b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b8e:	8b 55 14             	mov    0x14(%ebp),%edx
80107b91:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80107b94:	8b 45 e8             	mov    -0x18(%ebp),%eax
80107b97:	89 04 24             	mov    %eax,(%esp)
80107b9a:	e8 c5 f6 ff ff       	call   80107264 <p2v>
80107b9f:	8b 55 f0             	mov    -0x10(%ebp),%edx
80107ba2:	89 54 24 0c          	mov    %edx,0xc(%esp)
80107ba6:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80107baa:	89 44 24 04          	mov    %eax,0x4(%esp)
80107bae:	8b 45 10             	mov    0x10(%ebp),%eax
80107bb1:	89 04 24             	mov    %eax,(%esp)
80107bb4:	e8 9d a1 ff ff       	call   80101d56 <readi>
80107bb9:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80107bbc:	74 07                	je     80107bc5 <loaduvm+0xd1>
      return -1;
80107bbe:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107bc3:	eb 18                	jmp    80107bdd <loaduvm+0xe9>
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80107bc5:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80107bcc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107bcf:	3b 45 18             	cmp    0x18(%ebp),%eax
80107bd2:	0f 82 47 ff ff ff    	jb     80107b1f <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
80107bd8:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107bdd:	83 c4 24             	add    $0x24,%esp
80107be0:	5b                   	pop    %ebx
80107be1:	5d                   	pop    %ebp
80107be2:	c3                   	ret    

80107be3 <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80107be3:	55                   	push   %ebp
80107be4:	89 e5                	mov    %esp,%ebp
80107be6:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  uint a;

  if(newsz >= KERNBASE)
80107be9:	8b 45 10             	mov    0x10(%ebp),%eax
80107bec:	85 c0                	test   %eax,%eax
80107bee:	79 0a                	jns    80107bfa <allocuvm+0x17>
    return 0;
80107bf0:	b8 00 00 00 00       	mov    $0x0,%eax
80107bf5:	e9 c1 00 00 00       	jmp    80107cbb <allocuvm+0xd8>
  if(newsz < oldsz)
80107bfa:	8b 45 10             	mov    0x10(%ebp),%eax
80107bfd:	3b 45 0c             	cmp    0xc(%ebp),%eax
80107c00:	73 08                	jae    80107c0a <allocuvm+0x27>
    return oldsz;
80107c02:	8b 45 0c             	mov    0xc(%ebp),%eax
80107c05:	e9 b1 00 00 00       	jmp    80107cbb <allocuvm+0xd8>

  a = PGROUNDUP(oldsz);
80107c0a:	8b 45 0c             	mov    0xc(%ebp),%eax
80107c0d:	05 ff 0f 00 00       	add    $0xfff,%eax
80107c12:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107c17:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
80107c1a:	e9 8d 00 00 00       	jmp    80107cac <allocuvm+0xc9>
    mem = kalloc();
80107c1f:	e8 d3 ae ff ff       	call   80102af7 <kalloc>
80107c24:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(mem == 0){
80107c27:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107c2b:	75 2c                	jne    80107c59 <allocuvm+0x76>
      cprintf("allocuvm out of memory\n");
80107c2d:	c7 04 24 81 86 10 80 	movl   $0x80108681,(%esp)
80107c34:	e8 68 87 ff ff       	call   801003a1 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80107c39:	8b 45 0c             	mov    0xc(%ebp),%eax
80107c3c:	89 44 24 08          	mov    %eax,0x8(%esp)
80107c40:	8b 45 10             	mov    0x10(%ebp),%eax
80107c43:	89 44 24 04          	mov    %eax,0x4(%esp)
80107c47:	8b 45 08             	mov    0x8(%ebp),%eax
80107c4a:	89 04 24             	mov    %eax,(%esp)
80107c4d:	e8 6b 00 00 00       	call   80107cbd <deallocuvm>
      return 0;
80107c52:	b8 00 00 00 00       	mov    $0x0,%eax
80107c57:	eb 62                	jmp    80107cbb <allocuvm+0xd8>
    }
    memset(mem, 0, PGSIZE);
80107c59:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107c60:	00 
80107c61:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107c68:	00 
80107c69:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107c6c:	89 04 24             	mov    %eax,(%esp)
80107c6f:	e8 9e d0 ff ff       	call   80104d12 <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
80107c74:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107c77:	89 04 24             	mov    %eax,(%esp)
80107c7a:	e8 d8 f5 ff ff       	call   80107257 <v2p>
80107c7f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80107c82:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80107c89:	00 
80107c8a:	89 44 24 0c          	mov    %eax,0xc(%esp)
80107c8e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107c95:	00 
80107c96:	89 54 24 04          	mov    %edx,0x4(%esp)
80107c9a:	8b 45 08             	mov    0x8(%ebp),%eax
80107c9d:	89 04 24             	mov    %eax,(%esp)
80107ca0:	e8 d8 fa ff ff       	call   8010777d <mappages>
    return 0;
  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
80107ca5:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80107cac:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107caf:	3b 45 10             	cmp    0x10(%ebp),%eax
80107cb2:	0f 82 67 ff ff ff    	jb     80107c1f <allocuvm+0x3c>
      return 0;
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
  }
  return newsz;
80107cb8:	8b 45 10             	mov    0x10(%ebp),%eax
}
80107cbb:	c9                   	leave  
80107cbc:	c3                   	ret    

80107cbd <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80107cbd:	55                   	push   %ebp
80107cbe:	89 e5                	mov    %esp,%ebp
80107cc0:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
80107cc3:	8b 45 10             	mov    0x10(%ebp),%eax
80107cc6:	3b 45 0c             	cmp    0xc(%ebp),%eax
80107cc9:	72 08                	jb     80107cd3 <deallocuvm+0x16>
    return oldsz;
80107ccb:	8b 45 0c             	mov    0xc(%ebp),%eax
80107cce:	e9 a4 00 00 00       	jmp    80107d77 <deallocuvm+0xba>

  a = PGROUNDUP(newsz);
80107cd3:	8b 45 10             	mov    0x10(%ebp),%eax
80107cd6:	05 ff 0f 00 00       	add    $0xfff,%eax
80107cdb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107ce0:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
80107ce3:	e9 80 00 00 00       	jmp    80107d68 <deallocuvm+0xab>
    pte = walkpgdir(pgdir, (char*)a, 0);
80107ce8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ceb:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80107cf2:	00 
80107cf3:	89 44 24 04          	mov    %eax,0x4(%esp)
80107cf7:	8b 45 08             	mov    0x8(%ebp),%eax
80107cfa:	89 04 24             	mov    %eax,(%esp)
80107cfd:	e8 e5 f9 ff ff       	call   801076e7 <walkpgdir>
80107d02:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(!pte)
80107d05:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107d09:	75 09                	jne    80107d14 <deallocuvm+0x57>
      a += (NPTENTRIES - 1) * PGSIZE;
80107d0b:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
80107d12:	eb 4d                	jmp    80107d61 <deallocuvm+0xa4>
    else if((*pte & PTE_P) != 0){
80107d14:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107d17:	8b 00                	mov    (%eax),%eax
80107d19:	83 e0 01             	and    $0x1,%eax
80107d1c:	84 c0                	test   %al,%al
80107d1e:	74 41                	je     80107d61 <deallocuvm+0xa4>
      pa = PTE_ADDR(*pte);
80107d20:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107d23:	8b 00                	mov    (%eax),%eax
80107d25:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107d2a:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if(pa == 0)
80107d2d:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80107d31:	75 0c                	jne    80107d3f <deallocuvm+0x82>
        panic("kfree");
80107d33:	c7 04 24 99 86 10 80 	movl   $0x80108699,(%esp)
80107d3a:	e8 fe 87 ff ff       	call   8010053d <panic>
      char *v = p2v(pa);
80107d3f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107d42:	89 04 24             	mov    %eax,(%esp)
80107d45:	e8 1a f5 ff ff       	call   80107264 <p2v>
80107d4a:	89 45 e8             	mov    %eax,-0x18(%ebp)
      kfree(v);
80107d4d:	8b 45 e8             	mov    -0x18(%ebp),%eax
80107d50:	89 04 24             	mov    %eax,(%esp)
80107d53:	e8 06 ad ff ff       	call   80102a5e <kfree>
      *pte = 0;
80107d58:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107d5b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
80107d61:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80107d68:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d6b:	3b 45 0c             	cmp    0xc(%ebp),%eax
80107d6e:	0f 82 74 ff ff ff    	jb     80107ce8 <deallocuvm+0x2b>
      char *v = p2v(pa);
      kfree(v);
      *pte = 0;
    }
  }
  return newsz;
80107d74:	8b 45 10             	mov    0x10(%ebp),%eax
}
80107d77:	c9                   	leave  
80107d78:	c3                   	ret    

80107d79 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
80107d79:	55                   	push   %ebp
80107d7a:	89 e5                	mov    %esp,%ebp
80107d7c:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
80107d7f:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80107d83:	75 0c                	jne    80107d91 <freevm+0x18>
    panic("freevm: no pgdir");
80107d85:	c7 04 24 9f 86 10 80 	movl   $0x8010869f,(%esp)
80107d8c:	e8 ac 87 ff ff       	call   8010053d <panic>
  deallocuvm(pgdir, KERNBASE, 0);
80107d91:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80107d98:	00 
80107d99:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
80107da0:	80 
80107da1:	8b 45 08             	mov    0x8(%ebp),%eax
80107da4:	89 04 24             	mov    %eax,(%esp)
80107da7:	e8 11 ff ff ff       	call   80107cbd <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
80107dac:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80107db3:	eb 3c                	jmp    80107df1 <freevm+0x78>
    if(pgdir[i] & PTE_P){
80107db5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107db8:	c1 e0 02             	shl    $0x2,%eax
80107dbb:	03 45 08             	add    0x8(%ebp),%eax
80107dbe:	8b 00                	mov    (%eax),%eax
80107dc0:	83 e0 01             	and    $0x1,%eax
80107dc3:	84 c0                	test   %al,%al
80107dc5:	74 26                	je     80107ded <freevm+0x74>
      char * v = p2v(PTE_ADDR(pgdir[i]));
80107dc7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107dca:	c1 e0 02             	shl    $0x2,%eax
80107dcd:	03 45 08             	add    0x8(%ebp),%eax
80107dd0:	8b 00                	mov    (%eax),%eax
80107dd2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107dd7:	89 04 24             	mov    %eax,(%esp)
80107dda:	e8 85 f4 ff ff       	call   80107264 <p2v>
80107ddf:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
80107de2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107de5:	89 04 24             	mov    %eax,(%esp)
80107de8:	e8 71 ac ff ff       	call   80102a5e <kfree>
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
  for(i = 0; i < NPDENTRIES; i++){
80107ded:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80107df1:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
80107df8:	76 bb                	jbe    80107db5 <freevm+0x3c>
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
80107dfa:	8b 45 08             	mov    0x8(%ebp),%eax
80107dfd:	89 04 24             	mov    %eax,(%esp)
80107e00:	e8 59 ac ff ff       	call   80102a5e <kfree>
}
80107e05:	c9                   	leave  
80107e06:	c3                   	ret    

80107e07 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
80107e07:	55                   	push   %ebp
80107e08:	89 e5                	mov    %esp,%ebp
80107e0a:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80107e0d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80107e14:	00 
80107e15:	8b 45 0c             	mov    0xc(%ebp),%eax
80107e18:	89 44 24 04          	mov    %eax,0x4(%esp)
80107e1c:	8b 45 08             	mov    0x8(%ebp),%eax
80107e1f:	89 04 24             	mov    %eax,(%esp)
80107e22:	e8 c0 f8 ff ff       	call   801076e7 <walkpgdir>
80107e27:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
80107e2a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80107e2e:	75 0c                	jne    80107e3c <clearpteu+0x35>
    panic("clearpteu");
80107e30:	c7 04 24 b0 86 10 80 	movl   $0x801086b0,(%esp)
80107e37:	e8 01 87 ff ff       	call   8010053d <panic>
  *pte &= ~PTE_U;
80107e3c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e3f:	8b 00                	mov    (%eax),%eax
80107e41:	89 c2                	mov    %eax,%edx
80107e43:	83 e2 fb             	and    $0xfffffffb,%edx
80107e46:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e49:	89 10                	mov    %edx,(%eax)
}
80107e4b:	c9                   	leave  
80107e4c:	c3                   	ret    

80107e4d <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
80107e4d:	55                   	push   %ebp
80107e4e:	89 e5                	mov    %esp,%ebp
80107e50:	53                   	push   %ebx
80107e51:	83 ec 44             	sub    $0x44,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
80107e54:	e8 b8 f9 ff ff       	call   80107811 <setupkvm>
80107e59:	89 45 f0             	mov    %eax,-0x10(%ebp)
80107e5c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107e60:	75 0a                	jne    80107e6c <copyuvm+0x1f>
    return 0;
80107e62:	b8 00 00 00 00       	mov    $0x0,%eax
80107e67:	e9 fd 00 00 00       	jmp    80107f69 <copyuvm+0x11c>
  for(i = 0; i < sz; i += PGSIZE){
80107e6c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80107e73:	e9 cc 00 00 00       	jmp    80107f44 <copyuvm+0xf7>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
80107e78:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e7b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80107e82:	00 
80107e83:	89 44 24 04          	mov    %eax,0x4(%esp)
80107e87:	8b 45 08             	mov    0x8(%ebp),%eax
80107e8a:	89 04 24             	mov    %eax,(%esp)
80107e8d:	e8 55 f8 ff ff       	call   801076e7 <walkpgdir>
80107e92:	89 45 ec             	mov    %eax,-0x14(%ebp)
80107e95:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80107e99:	75 0c                	jne    80107ea7 <copyuvm+0x5a>
      panic("copyuvm: pte should exist");
80107e9b:	c7 04 24 ba 86 10 80 	movl   $0x801086ba,(%esp)
80107ea2:	e8 96 86 ff ff       	call   8010053d <panic>
    if(!(*pte & PTE_P))
80107ea7:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107eaa:	8b 00                	mov    (%eax),%eax
80107eac:	83 e0 01             	and    $0x1,%eax
80107eaf:	85 c0                	test   %eax,%eax
80107eb1:	75 0c                	jne    80107ebf <copyuvm+0x72>
      panic("copyuvm: page not present");
80107eb3:	c7 04 24 d4 86 10 80 	movl   $0x801086d4,(%esp)
80107eba:	e8 7e 86 ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
80107ebf:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107ec2:	8b 00                	mov    (%eax),%eax
80107ec4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107ec9:	89 45 e8             	mov    %eax,-0x18(%ebp)
    flags = PTE_FLAGS(*pte);
80107ecc:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107ecf:	8b 00                	mov    (%eax),%eax
80107ed1:	25 ff 0f 00 00       	and    $0xfff,%eax
80107ed6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if((mem = kalloc()) == 0)
80107ed9:	e8 19 ac ff ff       	call   80102af7 <kalloc>
80107ede:	89 45 e0             	mov    %eax,-0x20(%ebp)
80107ee1:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80107ee5:	74 6e                	je     80107f55 <copyuvm+0x108>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
80107ee7:	8b 45 e8             	mov    -0x18(%ebp),%eax
80107eea:	89 04 24             	mov    %eax,(%esp)
80107eed:	e8 72 f3 ff ff       	call   80107264 <p2v>
80107ef2:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107ef9:	00 
80107efa:	89 44 24 04          	mov    %eax,0x4(%esp)
80107efe:	8b 45 e0             	mov    -0x20(%ebp),%eax
80107f01:	89 04 24             	mov    %eax,(%esp)
80107f04:	e8 dc ce ff ff       	call   80104de5 <memmove>
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), flags) < 0)
80107f09:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
80107f0c:	8b 45 e0             	mov    -0x20(%ebp),%eax
80107f0f:	89 04 24             	mov    %eax,(%esp)
80107f12:	e8 40 f3 ff ff       	call   80107257 <v2p>
80107f17:	8b 55 f4             	mov    -0xc(%ebp),%edx
80107f1a:	89 5c 24 10          	mov    %ebx,0x10(%esp)
80107f1e:	89 44 24 0c          	mov    %eax,0xc(%esp)
80107f22:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107f29:	00 
80107f2a:	89 54 24 04          	mov    %edx,0x4(%esp)
80107f2e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107f31:	89 04 24             	mov    %eax,(%esp)
80107f34:	e8 44 f8 ff ff       	call   8010777d <mappages>
80107f39:	85 c0                	test   %eax,%eax
80107f3b:	78 1b                	js     80107f58 <copyuvm+0x10b>
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
80107f3d:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80107f44:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f47:	3b 45 0c             	cmp    0xc(%ebp),%eax
80107f4a:	0f 82 28 ff ff ff    	jb     80107e78 <copyuvm+0x2b>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), flags) < 0)
      goto bad;
  }
  return d;
80107f50:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107f53:	eb 14                	jmp    80107f69 <copyuvm+0x11c>
    if(!(*pte & PTE_P))
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
    flags = PTE_FLAGS(*pte);
    if((mem = kalloc()) == 0)
      goto bad;
80107f55:	90                   	nop
80107f56:	eb 01                	jmp    80107f59 <copyuvm+0x10c>
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), flags) < 0)
      goto bad;
80107f58:	90                   	nop
  }
  return d;

bad:
  freevm(d);
80107f59:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107f5c:	89 04 24             	mov    %eax,(%esp)
80107f5f:	e8 15 fe ff ff       	call   80107d79 <freevm>
  return 0;
80107f64:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107f69:	83 c4 44             	add    $0x44,%esp
80107f6c:	5b                   	pop    %ebx
80107f6d:	5d                   	pop    %ebp
80107f6e:	c3                   	ret    

80107f6f <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
80107f6f:	55                   	push   %ebp
80107f70:	89 e5                	mov    %esp,%ebp
80107f72:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80107f75:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80107f7c:	00 
80107f7d:	8b 45 0c             	mov    0xc(%ebp),%eax
80107f80:	89 44 24 04          	mov    %eax,0x4(%esp)
80107f84:	8b 45 08             	mov    0x8(%ebp),%eax
80107f87:	89 04 24             	mov    %eax,(%esp)
80107f8a:	e8 58 f7 ff ff       	call   801076e7 <walkpgdir>
80107f8f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
80107f92:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f95:	8b 00                	mov    (%eax),%eax
80107f97:	83 e0 01             	and    $0x1,%eax
80107f9a:	85 c0                	test   %eax,%eax
80107f9c:	75 07                	jne    80107fa5 <uva2ka+0x36>
    return 0;
80107f9e:	b8 00 00 00 00       	mov    $0x0,%eax
80107fa3:	eb 25                	jmp    80107fca <uva2ka+0x5b>
  if((*pte & PTE_U) == 0)
80107fa5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107fa8:	8b 00                	mov    (%eax),%eax
80107faa:	83 e0 04             	and    $0x4,%eax
80107fad:	85 c0                	test   %eax,%eax
80107faf:	75 07                	jne    80107fb8 <uva2ka+0x49>
    return 0;
80107fb1:	b8 00 00 00 00       	mov    $0x0,%eax
80107fb6:	eb 12                	jmp    80107fca <uva2ka+0x5b>
  return (char*)p2v(PTE_ADDR(*pte));
80107fb8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107fbb:	8b 00                	mov    (%eax),%eax
80107fbd:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107fc2:	89 04 24             	mov    %eax,(%esp)
80107fc5:	e8 9a f2 ff ff       	call   80107264 <p2v>
}
80107fca:	c9                   	leave  
80107fcb:	c3                   	ret    

80107fcc <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
80107fcc:	55                   	push   %ebp
80107fcd:	89 e5                	mov    %esp,%ebp
80107fcf:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
80107fd2:	8b 45 10             	mov    0x10(%ebp),%eax
80107fd5:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
80107fd8:	e9 8b 00 00 00       	jmp    80108068 <copyout+0x9c>
    va0 = (uint)PGROUNDDOWN(va);
80107fdd:	8b 45 0c             	mov    0xc(%ebp),%eax
80107fe0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107fe5:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
80107fe8:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107feb:	89 44 24 04          	mov    %eax,0x4(%esp)
80107fef:	8b 45 08             	mov    0x8(%ebp),%eax
80107ff2:	89 04 24             	mov    %eax,(%esp)
80107ff5:	e8 75 ff ff ff       	call   80107f6f <uva2ka>
80107ffa:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
80107ffd:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80108001:	75 07                	jne    8010800a <copyout+0x3e>
      return -1;
80108003:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108008:	eb 6d                	jmp    80108077 <copyout+0xab>
    n = PGSIZE - (va - va0);
8010800a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010800d:	8b 55 ec             	mov    -0x14(%ebp),%edx
80108010:	89 d1                	mov    %edx,%ecx
80108012:	29 c1                	sub    %eax,%ecx
80108014:	89 c8                	mov    %ecx,%eax
80108016:	05 00 10 00 00       	add    $0x1000,%eax
8010801b:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
8010801e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108021:	3b 45 14             	cmp    0x14(%ebp),%eax
80108024:	76 06                	jbe    8010802c <copyout+0x60>
      n = len;
80108026:	8b 45 14             	mov    0x14(%ebp),%eax
80108029:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
8010802c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010802f:	8b 55 0c             	mov    0xc(%ebp),%edx
80108032:	89 d1                	mov    %edx,%ecx
80108034:	29 c1                	sub    %eax,%ecx
80108036:	89 c8                	mov    %ecx,%eax
80108038:	03 45 e8             	add    -0x18(%ebp),%eax
8010803b:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010803e:	89 54 24 08          	mov    %edx,0x8(%esp)
80108042:	8b 55 f4             	mov    -0xc(%ebp),%edx
80108045:	89 54 24 04          	mov    %edx,0x4(%esp)
80108049:	89 04 24             	mov    %eax,(%esp)
8010804c:	e8 94 cd ff ff       	call   80104de5 <memmove>
    len -= n;
80108051:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108054:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
80108057:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010805a:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
8010805d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108060:	05 00 10 00 00       	add    $0x1000,%eax
80108065:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
80108068:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
8010806c:	0f 85 6b ff ff ff    	jne    80107fdd <copyout+0x11>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
80108072:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108077:	c9                   	leave  
80108078:	c3                   	ret    
