
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	94013103          	ld	sp,-1728(sp) # 80008940 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	95070713          	addi	a4,a4,-1712 # 800089a0 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	d1e78793          	addi	a5,a5,-738 # 80005d80 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc7ef>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dcc78793          	addi	a5,a5,-564 # 80000e78 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	39a080e7          	jalr	922(ra) # 800024c4 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	784080e7          	jalr	1924(ra) # 800008be <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	95650513          	addi	a0,a0,-1706 # 80010ae0 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	94648493          	addi	s1,s1,-1722 # 80010ae0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	9d690913          	addi	s2,s2,-1578 # 80010b78 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7ec080e7          	jalr	2028(ra) # 800019ac <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	146080e7          	jalr	326(ra) # 8000230e <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	e90080e7          	jalr	-368(ra) # 80002066 <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	25c080e7          	jalr	604(ra) # 8000246e <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	8ba50513          	addi	a0,a0,-1862 # 80010ae0 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	8a450513          	addi	a0,a0,-1884 # 80010ae0 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	90f72323          	sw	a5,-1786(a4) # 80010b78 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	560080e7          	jalr	1376(ra) # 800007ec <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54e080e7          	jalr	1358(ra) # 800007ec <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	542080e7          	jalr	1346(ra) # 800007ec <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	538080e7          	jalr	1336(ra) # 800007ec <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	81450513          	addi	a0,a0,-2028 # 80010ae0 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	228080e7          	jalr	552(ra) # 8000251a <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	7e650513          	addi	a0,a0,2022 # 80010ae0 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	7c270713          	addi	a4,a4,1986 # 80010ae0 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	79878793          	addi	a5,a5,1944 # 80010ae0 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	8027a783          	lw	a5,-2046(a5) # 80010b78 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	75670713          	addi	a4,a4,1878 # 80010ae0 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	74648493          	addi	s1,s1,1862 # 80010ae0 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	70a70713          	addi	a4,a4,1802 # 80010ae0 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	78f72a23          	sw	a5,1940(a4) # 80010b80 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	6ce78793          	addi	a5,a5,1742 # 80010ae0 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	74c7a323          	sw	a2,1862(a5) # 80010b7c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	73a50513          	addi	a0,a0,1850 # 80010b78 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	c84080e7          	jalr	-892(ra) # 800020ca <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	68050513          	addi	a0,a0,1664 # 80010ae0 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	a0078793          	addi	a5,a5,-1536 # 80020e78 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7670713          	addi	a4,a4,-906 # 80000100 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00010797          	auipc	a5,0x10
    80000550:	6407aa23          	sw	zero,1620(a5) # 80010ba0 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	b5a50513          	addi	a0,a0,-1190 # 800080c8 <digits+0x88>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00008717          	auipc	a4,0x8
    80000584:	3ef72023          	sw	a5,992(a4) # 80008960 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	8a2a                	mv	s4,a0
    800005aa:	e40c                	sd	a1,8(s0)
    800005ac:	e810                	sd	a2,16(s0)
    800005ae:	ec14                	sd	a3,24(s0)
    800005b0:	f018                	sd	a4,32(s0)
    800005b2:	f41c                	sd	a5,40(s0)
    800005b4:	03043823          	sd	a6,48(s0)
    800005b8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005bc:	00010d97          	auipc	s11,0x10
    800005c0:	5e4dad83          	lw	s11,1508(s11) # 80010ba0 <pr+0x18>
  if(locking)
    800005c4:	020d9b63          	bnez	s11,800005fa <printf+0x70>
  if (fmt == 0)
    800005c8:	040a0263          	beqz	s4,8000060c <printf+0x82>
  va_start(ap, fmt);
    800005cc:	00840793          	addi	a5,s0,8
    800005d0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d4:	000a4503          	lbu	a0,0(s4)
    800005d8:	14050f63          	beqz	a0,80000736 <printf+0x1ac>
    800005dc:	4981                	li	s3,0
    if(c != '%'){
    800005de:	02500a93          	li	s5,37
    switch(c){
    800005e2:	07000b93          	li	s7,112
  consputc('x');
    800005e6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e8:	00008b17          	auipc	s6,0x8
    800005ec:	a58b0b13          	addi	s6,s6,-1448 # 80008040 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00010517          	auipc	a0,0x10
    800005fe:	58e50513          	addi	a0,a0,1422 # 80010b88 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	5d4080e7          	jalr	1492(ra) # 80000bd6 <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a1c50513          	addi	a0,a0,-1508 # 80008028 <etext+0x28>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
      consputc(c);
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	c60080e7          	jalr	-928(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000624:	2985                	addiw	s3,s3,1
    80000626:	013a07b3          	add	a5,s4,s3
    8000062a:	0007c503          	lbu	a0,0(a5)
    8000062e:	10050463          	beqz	a0,80000736 <printf+0x1ac>
    if(c != '%'){
    80000632:	ff5515e3          	bne	a0,s5,8000061c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c783          	lbu	a5,0(a5)
    80000640:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000644:	cbed                	beqz	a5,80000736 <printf+0x1ac>
    switch(c){
    80000646:	05778a63          	beq	a5,s7,8000069a <printf+0x110>
    8000064a:	02fbf663          	bgeu	s7,a5,80000676 <printf+0xec>
    8000064e:	09978863          	beq	a5,s9,800006de <printf+0x154>
    80000652:	07800713          	li	a4,120
    80000656:	0ce79563          	bne	a5,a4,80000720 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065a:	f8843783          	ld	a5,-120(s0)
    8000065e:	00878713          	addi	a4,a5,8
    80000662:	f8e43423          	sd	a4,-120(s0)
    80000666:	4605                	li	a2,1
    80000668:	85ea                	mv	a1,s10
    8000066a:	4388                	lw	a0,0(a5)
    8000066c:	00000097          	auipc	ra,0x0
    80000670:	e30080e7          	jalr	-464(ra) # 8000049c <printint>
      break;
    80000674:	bf45                	j	80000624 <printf+0x9a>
    switch(c){
    80000676:	09578f63          	beq	a5,s5,80000714 <printf+0x18a>
    8000067a:	0b879363          	bne	a5,s8,80000720 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067e:	f8843783          	ld	a5,-120(s0)
    80000682:	00878713          	addi	a4,a5,8
    80000686:	f8e43423          	sd	a4,-120(s0)
    8000068a:	4605                	li	a2,1
    8000068c:	45a9                	li	a1,10
    8000068e:	4388                	lw	a0,0(a5)
    80000690:	00000097          	auipc	ra,0x0
    80000694:	e0c080e7          	jalr	-500(ra) # 8000049c <printint>
      break;
    80000698:	b771                	j	80000624 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069a:	f8843783          	ld	a5,-120(s0)
    8000069e:	00878713          	addi	a4,a5,8
    800006a2:	f8e43423          	sd	a4,-120(s0)
    800006a6:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006aa:	03000513          	li	a0,48
    800006ae:	00000097          	auipc	ra,0x0
    800006b2:	bce080e7          	jalr	-1074(ra) # 8000027c <consputc>
  consputc('x');
    800006b6:	07800513          	li	a0,120
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bc2080e7          	jalr	-1086(ra) # 8000027c <consputc>
    800006c2:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c4:	03c95793          	srli	a5,s2,0x3c
    800006c8:	97da                	add	a5,a5,s6
    800006ca:	0007c503          	lbu	a0,0(a5)
    800006ce:	00000097          	auipc	ra,0x0
    800006d2:	bae080e7          	jalr	-1106(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d6:	0912                	slli	s2,s2,0x4
    800006d8:	34fd                	addiw	s1,s1,-1
    800006da:	f4ed                	bnez	s1,800006c4 <printf+0x13a>
    800006dc:	b7a1                	j	80000624 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	6384                	ld	s1,0(a5)
    800006ec:	cc89                	beqz	s1,80000706 <printf+0x17c>
      for(; *s; s++)
    800006ee:	0004c503          	lbu	a0,0(s1)
    800006f2:	d90d                	beqz	a0,80000624 <printf+0x9a>
        consputc(*s);
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fc:	0485                	addi	s1,s1,1
    800006fe:	0004c503          	lbu	a0,0(s1)
    80000702:	f96d                	bnez	a0,800006f4 <printf+0x16a>
    80000704:	b705                	j	80000624 <printf+0x9a>
        s = "(null)";
    80000706:	00008497          	auipc	s1,0x8
    8000070a:	91a48493          	addi	s1,s1,-1766 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070e:	02800513          	li	a0,40
    80000712:	b7cd                	j	800006f4 <printf+0x16a>
      consputc('%');
    80000714:	8556                	mv	a0,s5
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b66080e7          	jalr	-1178(ra) # 8000027c <consputc>
      break;
    8000071e:	b719                	j	80000624 <printf+0x9a>
      consputc('%');
    80000720:	8556                	mv	a0,s5
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b5a080e7          	jalr	-1190(ra) # 8000027c <consputc>
      consputc(c);
    8000072a:	8526                	mv	a0,s1
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b50080e7          	jalr	-1200(ra) # 8000027c <consputc>
      break;
    80000734:	bdc5                	j	80000624 <printf+0x9a>
  if(locking)
    80000736:	020d9163          	bnez	s11,80000758 <printf+0x1ce>
}
    8000073a:	70e6                	ld	ra,120(sp)
    8000073c:	7446                	ld	s0,112(sp)
    8000073e:	74a6                	ld	s1,104(sp)
    80000740:	7906                	ld	s2,96(sp)
    80000742:	69e6                	ld	s3,88(sp)
    80000744:	6a46                	ld	s4,80(sp)
    80000746:	6aa6                	ld	s5,72(sp)
    80000748:	6b06                	ld	s6,64(sp)
    8000074a:	7be2                	ld	s7,56(sp)
    8000074c:	7c42                	ld	s8,48(sp)
    8000074e:	7ca2                	ld	s9,40(sp)
    80000750:	7d02                	ld	s10,32(sp)
    80000752:	6de2                	ld	s11,24(sp)
    80000754:	6129                	addi	sp,sp,192
    80000756:	8082                	ret
    release(&pr.lock);
    80000758:	00010517          	auipc	a0,0x10
    8000075c:	43050513          	addi	a0,a0,1072 # 80010b88 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	52a080e7          	jalr	1322(ra) # 80000c8a <release>
}
    80000768:	bfc9                	j	8000073a <printf+0x1b0>

000000008000076a <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076a:	1101                	addi	sp,sp,-32
    8000076c:	ec06                	sd	ra,24(sp)
    8000076e:	e822                	sd	s0,16(sp)
    80000770:	e426                	sd	s1,8(sp)
    80000772:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000774:	00010497          	auipc	s1,0x10
    80000778:	41448493          	addi	s1,s1,1044 # 80010b88 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	3c0080e7          	jalr	960(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078e:	4785                	li	a5,1
    80000790:	cc9c                	sw	a5,24(s1)
}
    80000792:	60e2                	ld	ra,24(sp)
    80000794:	6442                	ld	s0,16(sp)
    80000796:	64a2                	ld	s1,8(sp)
    80000798:	6105                	addi	sp,sp,32
    8000079a:	8082                	ret

000000008000079c <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079c:	1141                	addi	sp,sp,-16
    8000079e:	e406                	sd	ra,8(sp)
    800007a0:	e022                	sd	s0,0(sp)
    800007a2:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a4:	100007b7          	lui	a5,0x10000
    800007a8:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ac:	f8000713          	li	a4,-128
    800007b0:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b4:	470d                	li	a4,3
    800007b6:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007ba:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007be:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c2:	469d                	li	a3,7
    800007c4:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c8:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007cc:	00008597          	auipc	a1,0x8
    800007d0:	88c58593          	addi	a1,a1,-1908 # 80008058 <digits+0x18>
    800007d4:	00010517          	auipc	a0,0x10
    800007d8:	3d450513          	addi	a0,a0,980 # 80010ba8 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	36a080e7          	jalr	874(ra) # 80000b46 <initlock>
}
    800007e4:	60a2                	ld	ra,8(sp)
    800007e6:	6402                	ld	s0,0(sp)
    800007e8:	0141                	addi	sp,sp,16
    800007ea:	8082                	ret

00000000800007ec <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ec:	1101                	addi	sp,sp,-32
    800007ee:	ec06                	sd	ra,24(sp)
    800007f0:	e822                	sd	s0,16(sp)
    800007f2:	e426                	sd	s1,8(sp)
    800007f4:	1000                	addi	s0,sp,32
    800007f6:	84aa                	mv	s1,a0
  push_off();
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	392080e7          	jalr	914(ra) # 80000b8a <push_off>

  if(panicked){
    80000800:	00008797          	auipc	a5,0x8
    80000804:	1607a783          	lw	a5,352(a5) # 80008960 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080c:	c391                	beqz	a5,80000810 <uartputc_sync+0x24>
    for(;;)
    8000080e:	a001                	j	8000080e <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000810:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000814:	0207f793          	andi	a5,a5,32
    80000818:	dfe5                	beqz	a5,80000810 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081a:	0ff4f513          	zext.b	a0,s1
    8000081e:	100007b7          	lui	a5,0x10000
    80000822:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000826:	00000097          	auipc	ra,0x0
    8000082a:	404080e7          	jalr	1028(ra) # 80000c2a <pop_off>
}
    8000082e:	60e2                	ld	ra,24(sp)
    80000830:	6442                	ld	s0,16(sp)
    80000832:	64a2                	ld	s1,8(sp)
    80000834:	6105                	addi	sp,sp,32
    80000836:	8082                	ret

0000000080000838 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000838:	00008797          	auipc	a5,0x8
    8000083c:	1307b783          	ld	a5,304(a5) # 80008968 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	13073703          	ld	a4,304(a4) # 80008970 <uart_tx_w>
    80000848:	06f70a63          	beq	a4,a5,800008bc <uartstart+0x84>
{
    8000084c:	7139                	addi	sp,sp,-64
    8000084e:	fc06                	sd	ra,56(sp)
    80000850:	f822                	sd	s0,48(sp)
    80000852:	f426                	sd	s1,40(sp)
    80000854:	f04a                	sd	s2,32(sp)
    80000856:	ec4e                	sd	s3,24(sp)
    80000858:	e852                	sd	s4,16(sp)
    8000085a:	e456                	sd	s5,8(sp)
    8000085c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000862:	00010a17          	auipc	s4,0x10
    80000866:	346a0a13          	addi	s4,s4,838 # 80010ba8 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	0fe48493          	addi	s1,s1,254 # 80008968 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	0fe98993          	addi	s3,s3,254 # 80008970 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087a:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087e:	02077713          	andi	a4,a4,32
    80000882:	c705                	beqz	a4,800008aa <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000884:	01f7f713          	andi	a4,a5,31
    80000888:	9752                	add	a4,a4,s4
    8000088a:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088e:	0785                	addi	a5,a5,1
    80000890:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000892:	8526                	mv	a0,s1
    80000894:	00002097          	auipc	ra,0x2
    80000898:	836080e7          	jalr	-1994(ra) # 800020ca <wakeup>
    
    WriteReg(THR, c);
    8000089c:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008a0:	609c                	ld	a5,0(s1)
    800008a2:	0009b703          	ld	a4,0(s3)
    800008a6:	fcf71ae3          	bne	a4,a5,8000087a <uartstart+0x42>
  }
}
    800008aa:	70e2                	ld	ra,56(sp)
    800008ac:	7442                	ld	s0,48(sp)
    800008ae:	74a2                	ld	s1,40(sp)
    800008b0:	7902                	ld	s2,32(sp)
    800008b2:	69e2                	ld	s3,24(sp)
    800008b4:	6a42                	ld	s4,16(sp)
    800008b6:	6aa2                	ld	s5,8(sp)
    800008b8:	6121                	addi	sp,sp,64
    800008ba:	8082                	ret
    800008bc:	8082                	ret

00000000800008be <uartputc>:
{
    800008be:	7179                	addi	sp,sp,-48
    800008c0:	f406                	sd	ra,40(sp)
    800008c2:	f022                	sd	s0,32(sp)
    800008c4:	ec26                	sd	s1,24(sp)
    800008c6:	e84a                	sd	s2,16(sp)
    800008c8:	e44e                	sd	s3,8(sp)
    800008ca:	e052                	sd	s4,0(sp)
    800008cc:	1800                	addi	s0,sp,48
    800008ce:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008d0:	00010517          	auipc	a0,0x10
    800008d4:	2d850513          	addi	a0,a0,728 # 80010ba8 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	2fe080e7          	jalr	766(ra) # 80000bd6 <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	0807a783          	lw	a5,128(a5) # 80008960 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	08673703          	ld	a4,134(a4) # 80008970 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	0767b783          	ld	a5,118(a5) # 80008968 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	2aa98993          	addi	s3,s3,682 # 80010ba8 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	06248493          	addi	s1,s1,98 # 80008968 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	06290913          	addi	s2,s2,98 # 80008970 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00001097          	auipc	ra,0x1
    80000922:	748080e7          	jalr	1864(ra) # 80002066 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	27448493          	addi	s1,s1,628 # 80010ba8 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	02e7b423          	sd	a4,40(a5) # 80008970 <uart_tx_w>
  uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee8080e7          	jalr	-280(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	330080e7          	jalr	816(ra) # 80000c8a <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret
    for(;;)
    80000972:	a001                	j	80000972 <uartputc+0xb4>

0000000080000974 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000974:	1141                	addi	sp,sp,-16
    80000976:	e422                	sd	s0,8(sp)
    80000978:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000097a:	100007b7          	lui	a5,0x10000
    8000097e:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000982:	8b85                	andi	a5,a5,1
    80000984:	cb81                	beqz	a5,80000994 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098e:	6422                	ld	s0,8(sp)
    80000990:	0141                	addi	sp,sp,16
    80000992:	8082                	ret
    return -1;
    80000994:	557d                	li	a0,-1
    80000996:	bfe5                	j	8000098e <uartgetc+0x1a>

0000000080000998 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000998:	1101                	addi	sp,sp,-32
    8000099a:	ec06                	sd	ra,24(sp)
    8000099c:	e822                	sd	s0,16(sp)
    8000099e:	e426                	sd	s1,8(sp)
    800009a0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a2:	54fd                	li	s1,-1
    800009a4:	a029                	j	800009ae <uartintr+0x16>
      break;
    consoleintr(c);
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	918080e7          	jalr	-1768(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009ae:	00000097          	auipc	ra,0x0
    800009b2:	fc6080e7          	jalr	-58(ra) # 80000974 <uartgetc>
    if(c == -1)
    800009b6:	fe9518e3          	bne	a0,s1,800009a6 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ba:	00010497          	auipc	s1,0x10
    800009be:	1ee48493          	addi	s1,s1,494 # 80010ba8 <uart_tx_lock>
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	212080e7          	jalr	530(ra) # 80000bd6 <acquire>
  uartstart();
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	e6c080e7          	jalr	-404(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	2b4080e7          	jalr	692(ra) # 80000c8a <release>
}
    800009de:	60e2                	ld	ra,24(sp)
    800009e0:	6442                	ld	s0,16(sp)
    800009e2:	64a2                	ld	s1,8(sp)
    800009e4:	6105                	addi	sp,sp,32
    800009e6:	8082                	ret

00000000800009e8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e8:	1101                	addi	sp,sp,-32
    800009ea:	ec06                	sd	ra,24(sp)
    800009ec:	e822                	sd	s0,16(sp)
    800009ee:	e426                	sd	s1,8(sp)
    800009f0:	e04a                	sd	s2,0(sp)
    800009f2:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f4:	03451793          	slli	a5,a0,0x34
    800009f8:	ebb9                	bnez	a5,80000a4e <kfree+0x66>
    800009fa:	84aa                	mv	s1,a0
    800009fc:	00021797          	auipc	a5,0x21
    80000a00:	61478793          	addi	a5,a5,1556 # 80022010 <end>
    80000a04:	04f56563          	bltu	a0,a5,80000a4e <kfree+0x66>
    80000a08:	47c5                	li	a5,17
    80000a0a:	07ee                	slli	a5,a5,0x1b
    80000a0c:	04f57163          	bgeu	a0,a5,80000a4e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a10:	6605                	lui	a2,0x1
    80000a12:	4585                	li	a1,1
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	2be080e7          	jalr	702(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1c:	00010917          	auipc	s2,0x10
    80000a20:	1c490913          	addi	s2,s2,452 # 80010be0 <kmem>
    80000a24:	854a                	mv	a0,s2
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	1b0080e7          	jalr	432(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a2e:	01893783          	ld	a5,24(s2)
    80000a32:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a34:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a38:	854a                	mv	a0,s2
    80000a3a:	00000097          	auipc	ra,0x0
    80000a3e:	250080e7          	jalr	592(ra) # 80000c8a <release>
}
    80000a42:	60e2                	ld	ra,24(sp)
    80000a44:	6442                	ld	s0,16(sp)
    80000a46:	64a2                	ld	s1,8(sp)
    80000a48:	6902                	ld	s2,0(sp)
    80000a4a:	6105                	addi	sp,sp,32
    80000a4c:	8082                	ret
    panic("kfree");
    80000a4e:	00007517          	auipc	a0,0x7
    80000a52:	61250513          	addi	a0,a0,1554 # 80008060 <digits+0x20>
    80000a56:	00000097          	auipc	ra,0x0
    80000a5a:	aea080e7          	jalr	-1302(ra) # 80000540 <panic>

0000000080000a5e <freerange>:
{
    80000a5e:	7179                	addi	sp,sp,-48
    80000a60:	f406                	sd	ra,40(sp)
    80000a62:	f022                	sd	s0,32(sp)
    80000a64:	ec26                	sd	s1,24(sp)
    80000a66:	e84a                	sd	s2,16(sp)
    80000a68:	e44e                	sd	s3,8(sp)
    80000a6a:	e052                	sd	s4,0(sp)
    80000a6c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6e:	6785                	lui	a5,0x1
    80000a70:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a74:	00e504b3          	add	s1,a0,a4
    80000a78:	777d                	lui	a4,0xfffff
    80000a7a:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3c>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5c080e7          	jalr	-164(ra) # 800009e8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x2a>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	12650513          	addi	a0,a0,294 # 80010be0 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00021517          	auipc	a0,0x21
    80000ad2:	54250513          	addi	a0,a0,1346 # 80022010 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f88080e7          	jalr	-120(ra) # 80000a5e <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	0f048493          	addi	s1,s1,240 # 80010be0 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	0d850513          	addi	a0,a0,216 # 80010be0 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	0ac50513          	addi	a0,a0,172 # 80010be0 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	e20080e7          	jalr	-480(ra) # 80001990 <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	dee080e7          	jalr	-530(ra) # 80001990 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	de2080e7          	jalr	-542(ra) # 80001990 <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	dca080e7          	jalr	-566(ra) # 80001990 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	d8a080e7          	jalr	-630(ra) # 80001990 <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91e080e7          	jalr	-1762(ra) # 80000540 <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	d5e080e7          	jalr	-674(ra) # 80001990 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8ce080e7          	jalr	-1842(ra) # 80000540 <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8be080e7          	jalr	-1858(ra) # 80000540 <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	876080e7          	jalr	-1930(ra) # 80000540 <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdcff1>
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	40d707bb          	subw	a5,a4,a3
    80000e0c:	37fd                	addiw	a5,a5,-1
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	b00080e7          	jalr	-1280(ra) # 80001980 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	af070713          	addi	a4,a4,-1296 # 80008978 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	ae4080e7          	jalr	-1308(ra) # 80001980 <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6dc080e7          	jalr	1756(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	900080e7          	jalr	-1792(ra) # 800027be <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	efa080e7          	jalr	-262(ra) # 80005dc0 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	fda080e7          	jalr	-38(ra) # 80001ea8 <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88c080e7          	jalr	-1908(ra) # 8000076a <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	1e250513          	addi	a0,a0,482 # 800080c8 <digits+0x88>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69c080e7          	jalr	1692(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68c080e7          	jalr	1676(ra) # 8000058a <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	1c250513          	addi	a0,a0,450 # 800080c8 <digits+0x88>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67c080e7          	jalr	1660(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	326080e7          	jalr	806(ra) # 80001244 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	068080e7          	jalr	104(ra) # 80000f8e <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	99e080e7          	jalr	-1634(ra) # 800018cc <procinit>
    trapinit();      // trap vectors
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	860080e7          	jalr	-1952(ra) # 80002796 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	880080e7          	jalr	-1920(ra) # 800027be <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	e64080e7          	jalr	-412(ra) # 80005daa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	e72080e7          	jalr	-398(ra) # 80005dc0 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	008080e7          	jalr	8(ra) # 80002f5e <binit>
    iinit();         // inode table
    80000f5e:	00002097          	auipc	ra,0x2
    80000f62:	6a8080e7          	jalr	1704(ra) # 80003606 <iinit>
    fileinit();      // file table
    80000f66:	00003097          	auipc	ra,0x3
    80000f6a:	64e080e7          	jalr	1614(ra) # 800045b4 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	f5a080e7          	jalr	-166(ra) # 80005ec8 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	d14080e7          	jalr	-748(ra) # 80001c8a <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	9ef72a23          	sw	a5,-1548(a4) # 80008978 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f8e:	1141                	addi	sp,sp,-16
    80000f90:	e422                	sd	s0,8(sp)
    80000f92:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f94:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f98:	00008797          	auipc	a5,0x8
    80000f9c:	9e87b783          	ld	a5,-1560(a5) # 80008980 <kernel_pagetable>
    80000fa0:	83b1                	srli	a5,a5,0xc
    80000fa2:	577d                	li	a4,-1
    80000fa4:	177e                	slli	a4,a4,0x3f
    80000fa6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fac:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret

0000000080000fb6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb6:	7139                	addi	sp,sp,-64
    80000fb8:	fc06                	sd	ra,56(sp)
    80000fba:	f822                	sd	s0,48(sp)
    80000fbc:	f426                	sd	s1,40(sp)
    80000fbe:	f04a                	sd	s2,32(sp)
    80000fc0:	ec4e                	sd	s3,24(sp)
    80000fc2:	e852                	sd	s4,16(sp)
    80000fc4:	e456                	sd	s5,8(sp)
    80000fc6:	e05a                	sd	s6,0(sp)
    80000fc8:	0080                	addi	s0,sp,64
    80000fca:	84aa                	mv	s1,a0
    80000fcc:	89ae                	mv	s3,a1
    80000fce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd0:	57fd                	li	a5,-1
    80000fd2:	83e9                	srli	a5,a5,0x1a
    80000fd4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd8:	04b7f263          	bgeu	a5,a1,8000101c <walk+0x66>
    panic("walk");
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	0f450513          	addi	a0,a0,244 # 800080d0 <digits+0x90>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	55c080e7          	jalr	1372(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fec:	060a8663          	beqz	s5,80001058 <walk+0xa2>
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	af6080e7          	jalr	-1290(ra) # 80000ae6 <kalloc>
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	c529                	beqz	a0,80001044 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	4581                	li	a1,0
    80001000:	00000097          	auipc	ra,0x0
    80001004:	cd2080e7          	jalr	-814(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001008:	00c4d793          	srli	a5,s1,0xc
    8000100c:	07aa                	slli	a5,a5,0xa
    8000100e:	0017e793          	ori	a5,a5,1
    80001012:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001016:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdcfe7>
    80001018:	036a0063          	beq	s4,s6,80001038 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101c:	0149d933          	srl	s2,s3,s4
    80001020:	1ff97913          	andi	s2,s2,511
    80001024:	090e                	slli	s2,s2,0x3
    80001026:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001028:	00093483          	ld	s1,0(s2)
    8000102c:	0014f793          	andi	a5,s1,1
    80001030:	dfd5                	beqz	a5,80000fec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001032:	80a9                	srli	s1,s1,0xa
    80001034:	04b2                	slli	s1,s1,0xc
    80001036:	b7c5                	j	80001016 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001038:	00c9d513          	srli	a0,s3,0xc
    8000103c:	1ff57513          	andi	a0,a0,511
    80001040:	050e                	slli	a0,a0,0x3
    80001042:	9526                	add	a0,a0,s1
}
    80001044:	70e2                	ld	ra,56(sp)
    80001046:	7442                	ld	s0,48(sp)
    80001048:	74a2                	ld	s1,40(sp)
    8000104a:	7902                	ld	s2,32(sp)
    8000104c:	69e2                	ld	s3,24(sp)
    8000104e:	6a42                	ld	s4,16(sp)
    80001050:	6aa2                	ld	s5,8(sp)
    80001052:	6b02                	ld	s6,0(sp)
    80001054:	6121                	addi	sp,sp,64
    80001056:	8082                	ret
        return 0;
    80001058:	4501                	li	a0,0
    8000105a:	b7ed                	j	80001044 <walk+0x8e>

000000008000105c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	00b7f463          	bgeu	a5,a1,80001068 <walkaddr+0xc>
    return 0;
    80001064:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001066:	8082                	ret
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001070:	4601                	li	a2,0
    80001072:	00000097          	auipc	ra,0x0
    80001076:	f44080e7          	jalr	-188(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000107a:	c105                	beqz	a0,8000109a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000107e:	0117f693          	andi	a3,a5,17
    80001082:	4745                	li	a4,17
    return 0;
    80001084:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001086:	00e68663          	beq	a3,a4,80001092 <walkaddr+0x36>
}
    8000108a:	60a2                	ld	ra,8(sp)
    8000108c:	6402                	ld	s0,0(sp)
    8000108e:	0141                	addi	sp,sp,16
    80001090:	8082                	ret
  pa = PTE2PA(*pte);
    80001092:	83a9                	srli	a5,a5,0xa
    80001094:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001098:	bfcd                	j	8000108a <walkaddr+0x2e>
    return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7fd                	j	8000108a <walkaddr+0x2e>

000000008000109e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000109e:	715d                	addi	sp,sp,-80
    800010a0:	e486                	sd	ra,72(sp)
    800010a2:	e0a2                	sd	s0,64(sp)
    800010a4:	fc26                	sd	s1,56(sp)
    800010a6:	f84a                	sd	s2,48(sp)
    800010a8:	f44e                	sd	s3,40(sp)
    800010aa:	f052                	sd	s4,32(sp)
    800010ac:	ec56                	sd	s5,24(sp)
    800010ae:	e85a                	sd	s6,16(sp)
    800010b0:	e45e                	sd	s7,8(sp)
    800010b2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010b4:	c639                	beqz	a2,80001102 <mappages+0x64>
    800010b6:	8aaa                	mv	s5,a0
    800010b8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ba:	777d                	lui	a4,0xfffff
    800010bc:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010c0:	fff58993          	addi	s3,a1,-1
    800010c4:	99b2                	add	s3,s3,a2
    800010c6:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010ca:	893e                	mv	s2,a5
    800010cc:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d0:	6b85                	lui	s7,0x1
    800010d2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d6:	4605                	li	a2,1
    800010d8:	85ca                	mv	a1,s2
    800010da:	8556                	mv	a0,s5
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	eda080e7          	jalr	-294(ra) # 80000fb6 <walk>
    800010e4:	cd1d                	beqz	a0,80001122 <mappages+0x84>
    if(*pte & PTE_V)
    800010e6:	611c                	ld	a5,0(a0)
    800010e8:	8b85                	andi	a5,a5,1
    800010ea:	e785                	bnez	a5,80001112 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010ec:	80b1                	srli	s1,s1,0xc
    800010ee:	04aa                	slli	s1,s1,0xa
    800010f0:	0164e4b3          	or	s1,s1,s6
    800010f4:	0014e493          	ori	s1,s1,1
    800010f8:	e104                	sd	s1,0(a0)
    if(a == last)
    800010fa:	05390063          	beq	s2,s3,8000113a <mappages+0x9c>
    a += PGSIZE;
    800010fe:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001100:	bfc9                	j	800010d2 <mappages+0x34>
    panic("mappages: size");
    80001102:	00007517          	auipc	a0,0x7
    80001106:	fd650513          	addi	a0,a0,-42 # 800080d8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	436080e7          	jalr	1078(ra) # 80000540 <panic>
      panic("mappages: remap");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fd650513          	addi	a0,a0,-42 # 800080e8 <digits+0xa8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	426080e7          	jalr	1062(ra) # 80000540 <panic>
      return -1;
    80001122:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001124:	60a6                	ld	ra,72(sp)
    80001126:	6406                	ld	s0,64(sp)
    80001128:	74e2                	ld	s1,56(sp)
    8000112a:	7942                	ld	s2,48(sp)
    8000112c:	79a2                	ld	s3,40(sp)
    8000112e:	7a02                	ld	s4,32(sp)
    80001130:	6ae2                	ld	s5,24(sp)
    80001132:	6b42                	ld	s6,16(sp)
    80001134:	6ba2                	ld	s7,8(sp)
    80001136:	6161                	addi	sp,sp,80
    80001138:	8082                	ret
  return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7e5                	j	80001124 <mappages+0x86>

000000008000113e <kvmmap>:
{
    8000113e:	1141                	addi	sp,sp,-16
    80001140:	e406                	sd	ra,8(sp)
    80001142:	e022                	sd	s0,0(sp)
    80001144:	0800                	addi	s0,sp,16
    80001146:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001148:	86b2                	mv	a3,a2
    8000114a:	863e                	mv	a2,a5
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	f52080e7          	jalr	-174(ra) # 8000109e <mappages>
    80001154:	e509                	bnez	a0,8000115e <kvmmap+0x20>
}
    80001156:	60a2                	ld	ra,8(sp)
    80001158:	6402                	ld	s0,0(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
    panic("kvmmap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f9a50513          	addi	a0,a0,-102 # 800080f8 <digits+0xb8>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3da080e7          	jalr	986(ra) # 80000540 <panic>

000000008000116e <kvmmake>:
{
    8000116e:	1101                	addi	sp,sp,-32
    80001170:	ec06                	sd	ra,24(sp)
    80001172:	e822                	sd	s0,16(sp)
    80001174:	e426                	sd	s1,8(sp)
    80001176:	e04a                	sd	s2,0(sp)
    80001178:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80001182:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	b4a080e7          	jalr	-1206(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10000637          	lui	a2,0x10000
    80001198:	100005b7          	lui	a1,0x10000
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	fa0080e7          	jalr	-96(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	6685                	lui	a3,0x1
    800011aa:	10001637          	lui	a2,0x10001
    800011ae:	100015b7          	lui	a1,0x10001
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f8a080e7          	jalr	-118(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011bc:	4719                	li	a4,6
    800011be:	004006b7          	lui	a3,0x400
    800011c2:	0c000637          	lui	a2,0xc000
    800011c6:	0c0005b7          	lui	a1,0xc000
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f72080e7          	jalr	-142(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d4:	00007917          	auipc	s2,0x7
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80008000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80007697          	auipc	a3,0x80007
    800011e2:	e2268693          	addi	a3,a3,-478 # 8000 <_entry-0x7fff8000>
    800011e6:	4605                	li	a2,1
    800011e8:	067e                	slli	a2,a2,0x1f
    800011ea:	85b2                	mv	a1,a2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f50080e7          	jalr	-176(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	46c5                	li	a3,17
    800011fa:	06ee                	slli	a3,a3,0x1b
    800011fc:	412686b3          	sub	a3,a3,s2
    80001200:	864a                	mv	a2,s2
    80001202:	85ca                	mv	a1,s2
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f38080e7          	jalr	-200(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000120e:	4729                	li	a4,10
    80001210:	6685                	lui	a3,0x1
    80001212:	00006617          	auipc	a2,0x6
    80001216:	dee60613          	addi	a2,a2,-530 # 80007000 <_trampoline>
    8000121a:	040005b7          	lui	a1,0x4000
    8000121e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001220:	05b2                	slli	a1,a1,0xc
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f1a080e7          	jalr	-230(ra) # 8000113e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122c:	8526                	mv	a0,s1
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	608080e7          	jalr	1544(ra) # 80001836 <proc_mapstacks>
}
    80001236:	8526                	mv	a0,s1
    80001238:	60e2                	ld	ra,24(sp)
    8000123a:	6442                	ld	s0,16(sp)
    8000123c:	64a2                	ld	s1,8(sp)
    8000123e:	6902                	ld	s2,0(sp)
    80001240:	6105                	addi	sp,sp,32
    80001242:	8082                	ret

0000000080001244 <kvminit>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f22080e7          	jalr	-222(ra) # 8000116e <kvmmake>
    80001254:	00007797          	auipc	a5,0x7
    80001258:	72a7b623          	sd	a0,1836(a5) # 80008980 <kernel_pagetable>
}
    8000125c:	60a2                	ld	ra,8(sp)
    8000125e:	6402                	ld	s0,0(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001264:	715d                	addi	sp,sp,-80
    80001266:	e486                	sd	ra,72(sp)
    80001268:	e0a2                	sd	s0,64(sp)
    8000126a:	fc26                	sd	s1,56(sp)
    8000126c:	f84a                	sd	s2,48(sp)
    8000126e:	f44e                	sd	s3,40(sp)
    80001270:	f052                	sd	s4,32(sp)
    80001272:	ec56                	sd	s5,24(sp)
    80001274:	e85a                	sd	s6,16(sp)
    80001276:	e45e                	sd	s7,8(sp)
    80001278:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127a:	03459793          	slli	a5,a1,0x34
    8000127e:	e795                	bnez	a5,800012aa <uvmunmap+0x46>
    80001280:	8a2a                	mv	s4,a0
    80001282:	892e                	mv	s2,a1
    80001284:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	0632                	slli	a2,a2,0xc
    80001288:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	6b05                	lui	s6,0x1
    80001290:	0735e263          	bltu	a1,s3,800012f4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001294:	60a6                	ld	ra,72(sp)
    80001296:	6406                	ld	s0,64(sp)
    80001298:	74e2                	ld	s1,56(sp)
    8000129a:	7942                	ld	s2,48(sp)
    8000129c:	79a2                	ld	s3,40(sp)
    8000129e:	7a02                	ld	s4,32(sp)
    800012a0:	6ae2                	ld	s5,24(sp)
    800012a2:	6b42                	ld	s6,16(sp)
    800012a4:	6ba2                	ld	s7,8(sp)
    800012a6:	6161                	addi	sp,sp,80
    800012a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e5650513          	addi	a0,a0,-426 # 80008100 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28e080e7          	jalr	654(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e5e50513          	addi	a0,a0,-418 # 80008118 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27e080e7          	jalr	638(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e5e50513          	addi	a0,a0,-418 # 80008128 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26e080e7          	jalr	622(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e6650513          	addi	a0,a0,-410 # 80008140 <digits+0x100>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25e080e7          	jalr	606(ra) # 80000540 <panic>
    *pte = 0;
    800012ea:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ee:	995a                	add	s2,s2,s6
    800012f0:	fb3972e3          	bgeu	s2,s3,80001294 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f4:	4601                	li	a2,0
    800012f6:	85ca                	mv	a1,s2
    800012f8:	8552                	mv	a0,s4
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	cbc080e7          	jalr	-836(ra) # 80000fb6 <walk>
    80001302:	84aa                	mv	s1,a0
    80001304:	d95d                	beqz	a0,800012ba <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001306:	6108                	ld	a0,0(a0)
    80001308:	00157793          	andi	a5,a0,1
    8000130c:	dfdd                	beqz	a5,800012ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130e:	3ff57793          	andi	a5,a0,1023
    80001312:	fd7784e3          	beq	a5,s7,800012da <uvmunmap+0x76>
    if(do_free){
    80001316:	fc0a8ae3          	beqz	s5,800012ea <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000131a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000131c:	0532                	slli	a0,a0,0xc
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	6ca080e7          	jalr	1738(ra) # 800009e8 <kfree>
    80001326:	b7d1                	j	800012ea <uvmunmap+0x86>

0000000080001328 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001328:	1101                	addi	sp,sp,-32
    8000132a:	ec06                	sd	ra,24(sp)
    8000132c:	e822                	sd	s0,16(sp)
    8000132e:	e426                	sd	s1,8(sp)
    80001330:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	7b4080e7          	jalr	1972(ra) # 80000ae6 <kalloc>
    8000133a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000133c:	c519                	beqz	a0,8000134a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000133e:	6605                	lui	a2,0x1
    80001340:	4581                	li	a1,0
    80001342:	00000097          	auipc	ra,0x0
    80001346:	990080e7          	jalr	-1648(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000134a:	8526                	mv	a0,s1
    8000134c:	60e2                	ld	ra,24(sp)
    8000134e:	6442                	ld	s0,16(sp)
    80001350:	64a2                	ld	s1,8(sp)
    80001352:	6105                	addi	sp,sp,32
    80001354:	8082                	ret

0000000080001356 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001356:	7179                	addi	sp,sp,-48
    80001358:	f406                	sd	ra,40(sp)
    8000135a:	f022                	sd	s0,32(sp)
    8000135c:	ec26                	sd	s1,24(sp)
    8000135e:	e84a                	sd	s2,16(sp)
    80001360:	e44e                	sd	s3,8(sp)
    80001362:	e052                	sd	s4,0(sp)
    80001364:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001366:	6785                	lui	a5,0x1
    80001368:	04f67863          	bgeu	a2,a5,800013b8 <uvmfirst+0x62>
    8000136c:	8a2a                	mv	s4,a0
    8000136e:	89ae                	mv	s3,a1
    80001370:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	774080e7          	jalr	1908(ra) # 80000ae6 <kalloc>
    8000137a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000137c:	6605                	lui	a2,0x1
    8000137e:	4581                	li	a1,0
    80001380:	00000097          	auipc	ra,0x0
    80001384:	952080e7          	jalr	-1710(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001388:	4779                	li	a4,30
    8000138a:	86ca                	mv	a3,s2
    8000138c:	6605                	lui	a2,0x1
    8000138e:	4581                	li	a1,0
    80001390:	8552                	mv	a0,s4
    80001392:	00000097          	auipc	ra,0x0
    80001396:	d0c080e7          	jalr	-756(ra) # 8000109e <mappages>
  memmove(mem, src, sz);
    8000139a:	8626                	mv	a2,s1
    8000139c:	85ce                	mv	a1,s3
    8000139e:	854a                	mv	a0,s2
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	98e080e7          	jalr	-1650(ra) # 80000d2e <memmove>
}
    800013a8:	70a2                	ld	ra,40(sp)
    800013aa:	7402                	ld	s0,32(sp)
    800013ac:	64e2                	ld	s1,24(sp)
    800013ae:	6942                	ld	s2,16(sp)
    800013b0:	69a2                	ld	s3,8(sp)
    800013b2:	6a02                	ld	s4,0(sp)
    800013b4:	6145                	addi	sp,sp,48
    800013b6:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	da050513          	addi	a0,a0,-608 # 80008158 <digits+0x118>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	180080e7          	jalr	384(ra) # 80000540 <panic>

00000000800013c8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c8:	1101                	addi	sp,sp,-32
    800013ca:	ec06                	sd	ra,24(sp)
    800013cc:	e822                	sd	s0,16(sp)
    800013ce:	e426                	sd	s1,8(sp)
    800013d0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013d2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013d4:	00b67d63          	bgeu	a2,a1,800013ee <uvmdealloc+0x26>
    800013d8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013da:	6785                	lui	a5,0x1
    800013dc:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013de:	00f60733          	add	a4,a2,a5
    800013e2:	76fd                	lui	a3,0xfffff
    800013e4:	8f75                	and	a4,a4,a3
    800013e6:	97ae                	add	a5,a5,a1
    800013e8:	8ff5                	and	a5,a5,a3
    800013ea:	00f76863          	bltu	a4,a5,800013fa <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013ee:	8526                	mv	a0,s1
    800013f0:	60e2                	ld	ra,24(sp)
    800013f2:	6442                	ld	s0,16(sp)
    800013f4:	64a2                	ld	s1,8(sp)
    800013f6:	6105                	addi	sp,sp,32
    800013f8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013fa:	8f99                	sub	a5,a5,a4
    800013fc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013fe:	4685                	li	a3,1
    80001400:	0007861b          	sext.w	a2,a5
    80001404:	85ba                	mv	a1,a4
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	e5e080e7          	jalr	-418(ra) # 80001264 <uvmunmap>
    8000140e:	b7c5                	j	800013ee <uvmdealloc+0x26>

0000000080001410 <uvmalloc>:
  if(newsz < oldsz)
    80001410:	0ab66563          	bltu	a2,a1,800014ba <uvmalloc+0xaa>
{
    80001414:	7139                	addi	sp,sp,-64
    80001416:	fc06                	sd	ra,56(sp)
    80001418:	f822                	sd	s0,48(sp)
    8000141a:	f426                	sd	s1,40(sp)
    8000141c:	f04a                	sd	s2,32(sp)
    8000141e:	ec4e                	sd	s3,24(sp)
    80001420:	e852                	sd	s4,16(sp)
    80001422:	e456                	sd	s5,8(sp)
    80001424:	e05a                	sd	s6,0(sp)
    80001426:	0080                	addi	s0,sp,64
    80001428:	8aaa                	mv	s5,a0
    8000142a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000142c:	6785                	lui	a5,0x1
    8000142e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001430:	95be                	add	a1,a1,a5
    80001432:	77fd                	lui	a5,0xfffff
    80001434:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001438:	08c9f363          	bgeu	s3,a2,800014be <uvmalloc+0xae>
    8000143c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000143e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	6a4080e7          	jalr	1700(ra) # 80000ae6 <kalloc>
    8000144a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000144c:	c51d                	beqz	a0,8000147a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	00000097          	auipc	ra,0x0
    80001456:	880080e7          	jalr	-1920(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	875a                	mv	a4,s6
    8000145c:	86a6                	mv	a3,s1
    8000145e:	6605                	lui	a2,0x1
    80001460:	85ca                	mv	a1,s2
    80001462:	8556                	mv	a0,s5
    80001464:	00000097          	auipc	ra,0x0
    80001468:	c3a080e7          	jalr	-966(ra) # 8000109e <mappages>
    8000146c:	e90d                	bnez	a0,8000149e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146e:	6785                	lui	a5,0x1
    80001470:	993e                	add	s2,s2,a5
    80001472:	fd4968e3          	bltu	s2,s4,80001442 <uvmalloc+0x32>
  return newsz;
    80001476:	8552                	mv	a0,s4
    80001478:	a809                	j	8000148a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000147a:	864e                	mv	a2,s3
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	f48080e7          	jalr	-184(ra) # 800013c8 <uvmdealloc>
      return 0;
    80001488:	4501                	li	a0,0
}
    8000148a:	70e2                	ld	ra,56(sp)
    8000148c:	7442                	ld	s0,48(sp)
    8000148e:	74a2                	ld	s1,40(sp)
    80001490:	7902                	ld	s2,32(sp)
    80001492:	69e2                	ld	s3,24(sp)
    80001494:	6a42                	ld	s4,16(sp)
    80001496:	6aa2                	ld	s5,8(sp)
    80001498:	6b02                	ld	s6,0(sp)
    8000149a:	6121                	addi	sp,sp,64
    8000149c:	8082                	ret
      kfree(mem);
    8000149e:	8526                	mv	a0,s1
    800014a0:	fffff097          	auipc	ra,0xfffff
    800014a4:	548080e7          	jalr	1352(ra) # 800009e8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a8:	864e                	mv	a2,s3
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	f1a080e7          	jalr	-230(ra) # 800013c8 <uvmdealloc>
      return 0;
    800014b6:	4501                	li	a0,0
    800014b8:	bfc9                	j	8000148a <uvmalloc+0x7a>
    return oldsz;
    800014ba:	852e                	mv	a0,a1
}
    800014bc:	8082                	ret
  return newsz;
    800014be:	8532                	mv	a0,a2
    800014c0:	b7e9                	j	8000148a <uvmalloc+0x7a>

00000000800014c2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014c2:	7179                	addi	sp,sp,-48
    800014c4:	f406                	sd	ra,40(sp)
    800014c6:	f022                	sd	s0,32(sp)
    800014c8:	ec26                	sd	s1,24(sp)
    800014ca:	e84a                	sd	s2,16(sp)
    800014cc:	e44e                	sd	s3,8(sp)
    800014ce:	e052                	sd	s4,0(sp)
    800014d0:	1800                	addi	s0,sp,48
    800014d2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014d4:	84aa                	mv	s1,a0
    800014d6:	6905                	lui	s2,0x1
    800014d8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014da:	4985                	li	s3,1
    800014dc:	a829                	j	800014f6 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014de:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014e0:	00c79513          	slli	a0,a5,0xc
    800014e4:	00000097          	auipc	ra,0x0
    800014e8:	fde080e7          	jalr	-34(ra) # 800014c2 <freewalk>
      pagetable[i] = 0;
    800014ec:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f0:	04a1                	addi	s1,s1,8
    800014f2:	03248163          	beq	s1,s2,80001514 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014f6:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f8:	00f7f713          	andi	a4,a5,15
    800014fc:	ff3701e3          	beq	a4,s3,800014de <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001500:	8b85                	andi	a5,a5,1
    80001502:	d7fd                	beqz	a5,800014f0 <freewalk+0x2e>
      panic("freewalk: leaf");
    80001504:	00007517          	auipc	a0,0x7
    80001508:	c7450513          	addi	a0,a0,-908 # 80008178 <digits+0x138>
    8000150c:	fffff097          	auipc	ra,0xfffff
    80001510:	034080e7          	jalr	52(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    80001514:	8552                	mv	a0,s4
    80001516:	fffff097          	auipc	ra,0xfffff
    8000151a:	4d2080e7          	jalr	1234(ra) # 800009e8 <kfree>
}
    8000151e:	70a2                	ld	ra,40(sp)
    80001520:	7402                	ld	s0,32(sp)
    80001522:	64e2                	ld	s1,24(sp)
    80001524:	6942                	ld	s2,16(sp)
    80001526:	69a2                	ld	s3,8(sp)
    80001528:	6a02                	ld	s4,0(sp)
    8000152a:	6145                	addi	sp,sp,48
    8000152c:	8082                	ret

000000008000152e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000152e:	1101                	addi	sp,sp,-32
    80001530:	ec06                	sd	ra,24(sp)
    80001532:	e822                	sd	s0,16(sp)
    80001534:	e426                	sd	s1,8(sp)
    80001536:	1000                	addi	s0,sp,32
    80001538:	84aa                	mv	s1,a0
  if(sz > 0)
    8000153a:	e999                	bnez	a1,80001550 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000153c:	8526                	mv	a0,s1
    8000153e:	00000097          	auipc	ra,0x0
    80001542:	f84080e7          	jalr	-124(ra) # 800014c2 <freewalk>
}
    80001546:	60e2                	ld	ra,24(sp)
    80001548:	6442                	ld	s0,16(sp)
    8000154a:	64a2                	ld	s1,8(sp)
    8000154c:	6105                	addi	sp,sp,32
    8000154e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001550:	6785                	lui	a5,0x1
    80001552:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001554:	95be                	add	a1,a1,a5
    80001556:	4685                	li	a3,1
    80001558:	00c5d613          	srli	a2,a1,0xc
    8000155c:	4581                	li	a1,0
    8000155e:	00000097          	auipc	ra,0x0
    80001562:	d06080e7          	jalr	-762(ra) # 80001264 <uvmunmap>
    80001566:	bfd9                	j	8000153c <uvmfree+0xe>

0000000080001568 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001568:	c679                	beqz	a2,80001636 <uvmcopy+0xce>
{
    8000156a:	715d                	addi	sp,sp,-80
    8000156c:	e486                	sd	ra,72(sp)
    8000156e:	e0a2                	sd	s0,64(sp)
    80001570:	fc26                	sd	s1,56(sp)
    80001572:	f84a                	sd	s2,48(sp)
    80001574:	f44e                	sd	s3,40(sp)
    80001576:	f052                	sd	s4,32(sp)
    80001578:	ec56                	sd	s5,24(sp)
    8000157a:	e85a                	sd	s6,16(sp)
    8000157c:	e45e                	sd	s7,8(sp)
    8000157e:	0880                	addi	s0,sp,80
    80001580:	8b2a                	mv	s6,a0
    80001582:	8aae                	mv	s5,a1
    80001584:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001586:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001588:	4601                	li	a2,0
    8000158a:	85ce                	mv	a1,s3
    8000158c:	855a                	mv	a0,s6
    8000158e:	00000097          	auipc	ra,0x0
    80001592:	a28080e7          	jalr	-1496(ra) # 80000fb6 <walk>
    80001596:	c531                	beqz	a0,800015e2 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001598:	6118                	ld	a4,0(a0)
    8000159a:	00177793          	andi	a5,a4,1
    8000159e:	cbb1                	beqz	a5,800015f2 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a0:	00a75593          	srli	a1,a4,0xa
    800015a4:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a8:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ac:	fffff097          	auipc	ra,0xfffff
    800015b0:	53a080e7          	jalr	1338(ra) # 80000ae6 <kalloc>
    800015b4:	892a                	mv	s2,a0
    800015b6:	c939                	beqz	a0,8000160c <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b8:	6605                	lui	a2,0x1
    800015ba:	85de                	mv	a1,s7
    800015bc:	fffff097          	auipc	ra,0xfffff
    800015c0:	772080e7          	jalr	1906(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c4:	8726                	mv	a4,s1
    800015c6:	86ca                	mv	a3,s2
    800015c8:	6605                	lui	a2,0x1
    800015ca:	85ce                	mv	a1,s3
    800015cc:	8556                	mv	a0,s5
    800015ce:	00000097          	auipc	ra,0x0
    800015d2:	ad0080e7          	jalr	-1328(ra) # 8000109e <mappages>
    800015d6:	e515                	bnez	a0,80001602 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d8:	6785                	lui	a5,0x1
    800015da:	99be                	add	s3,s3,a5
    800015dc:	fb49e6e3          	bltu	s3,s4,80001588 <uvmcopy+0x20>
    800015e0:	a081                	j	80001620 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e2:	00007517          	auipc	a0,0x7
    800015e6:	ba650513          	addi	a0,a0,-1114 # 80008188 <digits+0x148>
    800015ea:	fffff097          	auipc	ra,0xfffff
    800015ee:	f56080e7          	jalr	-170(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    800015f2:	00007517          	auipc	a0,0x7
    800015f6:	bb650513          	addi	a0,a0,-1098 # 800081a8 <digits+0x168>
    800015fa:	fffff097          	auipc	ra,0xfffff
    800015fe:	f46080e7          	jalr	-186(ra) # 80000540 <panic>
      kfree(mem);
    80001602:	854a                	mv	a0,s2
    80001604:	fffff097          	auipc	ra,0xfffff
    80001608:	3e4080e7          	jalr	996(ra) # 800009e8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000160c:	4685                	li	a3,1
    8000160e:	00c9d613          	srli	a2,s3,0xc
    80001612:	4581                	li	a1,0
    80001614:	8556                	mv	a0,s5
    80001616:	00000097          	auipc	ra,0x0
    8000161a:	c4e080e7          	jalr	-946(ra) # 80001264 <uvmunmap>
  return -1;
    8000161e:	557d                	li	a0,-1
}
    80001620:	60a6                	ld	ra,72(sp)
    80001622:	6406                	ld	s0,64(sp)
    80001624:	74e2                	ld	s1,56(sp)
    80001626:	7942                	ld	s2,48(sp)
    80001628:	79a2                	ld	s3,40(sp)
    8000162a:	7a02                	ld	s4,32(sp)
    8000162c:	6ae2                	ld	s5,24(sp)
    8000162e:	6b42                	ld	s6,16(sp)
    80001630:	6ba2                	ld	s7,8(sp)
    80001632:	6161                	addi	sp,sp,80
    80001634:	8082                	ret
  return 0;
    80001636:	4501                	li	a0,0
}
    80001638:	8082                	ret

000000008000163a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000163a:	1141                	addi	sp,sp,-16
    8000163c:	e406                	sd	ra,8(sp)
    8000163e:	e022                	sd	s0,0(sp)
    80001640:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001642:	4601                	li	a2,0
    80001644:	00000097          	auipc	ra,0x0
    80001648:	972080e7          	jalr	-1678(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000164c:	c901                	beqz	a0,8000165c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000164e:	611c                	ld	a5,0(a0)
    80001650:	9bbd                	andi	a5,a5,-17
    80001652:	e11c                	sd	a5,0(a0)
}
    80001654:	60a2                	ld	ra,8(sp)
    80001656:	6402                	ld	s0,0(sp)
    80001658:	0141                	addi	sp,sp,16
    8000165a:	8082                	ret
    panic("uvmclear");
    8000165c:	00007517          	auipc	a0,0x7
    80001660:	b6c50513          	addi	a0,a0,-1172 # 800081c8 <digits+0x188>
    80001664:	fffff097          	auipc	ra,0xfffff
    80001668:	edc080e7          	jalr	-292(ra) # 80000540 <panic>

000000008000166c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000166c:	c6bd                	beqz	a3,800016da <copyout+0x6e>
{
    8000166e:	715d                	addi	sp,sp,-80
    80001670:	e486                	sd	ra,72(sp)
    80001672:	e0a2                	sd	s0,64(sp)
    80001674:	fc26                	sd	s1,56(sp)
    80001676:	f84a                	sd	s2,48(sp)
    80001678:	f44e                	sd	s3,40(sp)
    8000167a:	f052                	sd	s4,32(sp)
    8000167c:	ec56                	sd	s5,24(sp)
    8000167e:	e85a                	sd	s6,16(sp)
    80001680:	e45e                	sd	s7,8(sp)
    80001682:	e062                	sd	s8,0(sp)
    80001684:	0880                	addi	s0,sp,80
    80001686:	8b2a                	mv	s6,a0
    80001688:	8c2e                	mv	s8,a1
    8000168a:	8a32                	mv	s4,a2
    8000168c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000168e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001690:	6a85                	lui	s5,0x1
    80001692:	a015                	j	800016b6 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001694:	9562                	add	a0,a0,s8
    80001696:	0004861b          	sext.w	a2,s1
    8000169a:	85d2                	mv	a1,s4
    8000169c:	41250533          	sub	a0,a0,s2
    800016a0:	fffff097          	auipc	ra,0xfffff
    800016a4:	68e080e7          	jalr	1678(ra) # 80000d2e <memmove>

    len -= n;
    800016a8:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ac:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016ae:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b2:	02098263          	beqz	s3,800016d6 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b6:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016ba:	85ca                	mv	a1,s2
    800016bc:	855a                	mv	a0,s6
    800016be:	00000097          	auipc	ra,0x0
    800016c2:	99e080e7          	jalr	-1634(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800016c6:	cd01                	beqz	a0,800016de <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c8:	418904b3          	sub	s1,s2,s8
    800016cc:	94d6                	add	s1,s1,s5
    800016ce:	fc99f3e3          	bgeu	s3,s1,80001694 <copyout+0x28>
    800016d2:	84ce                	mv	s1,s3
    800016d4:	b7c1                	j	80001694 <copyout+0x28>
  }
  return 0;
    800016d6:	4501                	li	a0,0
    800016d8:	a021                	j	800016e0 <copyout+0x74>
    800016da:	4501                	li	a0,0
}
    800016dc:	8082                	ret
      return -1;
    800016de:	557d                	li	a0,-1
}
    800016e0:	60a6                	ld	ra,72(sp)
    800016e2:	6406                	ld	s0,64(sp)
    800016e4:	74e2                	ld	s1,56(sp)
    800016e6:	7942                	ld	s2,48(sp)
    800016e8:	79a2                	ld	s3,40(sp)
    800016ea:	7a02                	ld	s4,32(sp)
    800016ec:	6ae2                	ld	s5,24(sp)
    800016ee:	6b42                	ld	s6,16(sp)
    800016f0:	6ba2                	ld	s7,8(sp)
    800016f2:	6c02                	ld	s8,0(sp)
    800016f4:	6161                	addi	sp,sp,80
    800016f6:	8082                	ret

00000000800016f8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f8:	caa5                	beqz	a3,80001768 <copyin+0x70>
{
    800016fa:	715d                	addi	sp,sp,-80
    800016fc:	e486                	sd	ra,72(sp)
    800016fe:	e0a2                	sd	s0,64(sp)
    80001700:	fc26                	sd	s1,56(sp)
    80001702:	f84a                	sd	s2,48(sp)
    80001704:	f44e                	sd	s3,40(sp)
    80001706:	f052                	sd	s4,32(sp)
    80001708:	ec56                	sd	s5,24(sp)
    8000170a:	e85a                	sd	s6,16(sp)
    8000170c:	e45e                	sd	s7,8(sp)
    8000170e:	e062                	sd	s8,0(sp)
    80001710:	0880                	addi	s0,sp,80
    80001712:	8b2a                	mv	s6,a0
    80001714:	8a2e                	mv	s4,a1
    80001716:	8c32                	mv	s8,a2
    80001718:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000171a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000171c:	6a85                	lui	s5,0x1
    8000171e:	a01d                	j	80001744 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001720:	018505b3          	add	a1,a0,s8
    80001724:	0004861b          	sext.w	a2,s1
    80001728:	412585b3          	sub	a1,a1,s2
    8000172c:	8552                	mv	a0,s4
    8000172e:	fffff097          	auipc	ra,0xfffff
    80001732:	600080e7          	jalr	1536(ra) # 80000d2e <memmove>

    len -= n;
    80001736:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173a:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000173c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001740:	02098263          	beqz	s3,80001764 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001744:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001748:	85ca                	mv	a1,s2
    8000174a:	855a                	mv	a0,s6
    8000174c:	00000097          	auipc	ra,0x0
    80001750:	910080e7          	jalr	-1776(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    80001754:	cd01                	beqz	a0,8000176c <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001756:	418904b3          	sub	s1,s2,s8
    8000175a:	94d6                	add	s1,s1,s5
    8000175c:	fc99f2e3          	bgeu	s3,s1,80001720 <copyin+0x28>
    80001760:	84ce                	mv	s1,s3
    80001762:	bf7d                	j	80001720 <copyin+0x28>
  }
  return 0;
    80001764:	4501                	li	a0,0
    80001766:	a021                	j	8000176e <copyin+0x76>
    80001768:	4501                	li	a0,0
}
    8000176a:	8082                	ret
      return -1;
    8000176c:	557d                	li	a0,-1
}
    8000176e:	60a6                	ld	ra,72(sp)
    80001770:	6406                	ld	s0,64(sp)
    80001772:	74e2                	ld	s1,56(sp)
    80001774:	7942                	ld	s2,48(sp)
    80001776:	79a2                	ld	s3,40(sp)
    80001778:	7a02                	ld	s4,32(sp)
    8000177a:	6ae2                	ld	s5,24(sp)
    8000177c:	6b42                	ld	s6,16(sp)
    8000177e:	6ba2                	ld	s7,8(sp)
    80001780:	6c02                	ld	s8,0(sp)
    80001782:	6161                	addi	sp,sp,80
    80001784:	8082                	ret

0000000080001786 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001786:	c2dd                	beqz	a3,8000182c <copyinstr+0xa6>
{
    80001788:	715d                	addi	sp,sp,-80
    8000178a:	e486                	sd	ra,72(sp)
    8000178c:	e0a2                	sd	s0,64(sp)
    8000178e:	fc26                	sd	s1,56(sp)
    80001790:	f84a                	sd	s2,48(sp)
    80001792:	f44e                	sd	s3,40(sp)
    80001794:	f052                	sd	s4,32(sp)
    80001796:	ec56                	sd	s5,24(sp)
    80001798:	e85a                	sd	s6,16(sp)
    8000179a:	e45e                	sd	s7,8(sp)
    8000179c:	0880                	addi	s0,sp,80
    8000179e:	8a2a                	mv	s4,a0
    800017a0:	8b2e                	mv	s6,a1
    800017a2:	8bb2                	mv	s7,a2
    800017a4:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a6:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a8:	6985                	lui	s3,0x1
    800017aa:	a02d                	j	800017d4 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017ac:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b0:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b2:	37fd                	addiw	a5,a5,-1
    800017b4:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b8:	60a6                	ld	ra,72(sp)
    800017ba:	6406                	ld	s0,64(sp)
    800017bc:	74e2                	ld	s1,56(sp)
    800017be:	7942                	ld	s2,48(sp)
    800017c0:	79a2                	ld	s3,40(sp)
    800017c2:	7a02                	ld	s4,32(sp)
    800017c4:	6ae2                	ld	s5,24(sp)
    800017c6:	6b42                	ld	s6,16(sp)
    800017c8:	6ba2                	ld	s7,8(sp)
    800017ca:	6161                	addi	sp,sp,80
    800017cc:	8082                	ret
    srcva = va0 + PGSIZE;
    800017ce:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d2:	c8a9                	beqz	s1,80001824 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017d4:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d8:	85ca                	mv	a1,s2
    800017da:	8552                	mv	a0,s4
    800017dc:	00000097          	auipc	ra,0x0
    800017e0:	880080e7          	jalr	-1920(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800017e4:	c131                	beqz	a0,80001828 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017e6:	417906b3          	sub	a3,s2,s7
    800017ea:	96ce                	add	a3,a3,s3
    800017ec:	00d4f363          	bgeu	s1,a3,800017f2 <copyinstr+0x6c>
    800017f0:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f2:	955e                	add	a0,a0,s7
    800017f4:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f8:	daf9                	beqz	a3,800017ce <copyinstr+0x48>
    800017fa:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017fc:	41650633          	sub	a2,a0,s6
    80001800:	fff48593          	addi	a1,s1,-1
    80001804:	95da                	add	a1,a1,s6
    while(n > 0){
    80001806:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001808:	00f60733          	add	a4,a2,a5
    8000180c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdcff0>
    80001810:	df51                	beqz	a4,800017ac <copyinstr+0x26>
        *dst = *p;
    80001812:	00e78023          	sb	a4,0(a5)
      --max;
    80001816:	40f584b3          	sub	s1,a1,a5
      dst++;
    8000181a:	0785                	addi	a5,a5,1
    while(n > 0){
    8000181c:	fed796e3          	bne	a5,a3,80001808 <copyinstr+0x82>
      dst++;
    80001820:	8b3e                	mv	s6,a5
    80001822:	b775                	j	800017ce <copyinstr+0x48>
    80001824:	4781                	li	a5,0
    80001826:	b771                	j	800017b2 <copyinstr+0x2c>
      return -1;
    80001828:	557d                	li	a0,-1
    8000182a:	b779                	j	800017b8 <copyinstr+0x32>
  int got_null = 0;
    8000182c:	4781                	li	a5,0
  if(got_null){
    8000182e:	37fd                	addiw	a5,a5,-1
    80001830:	0007851b          	sext.w	a0,a5
}
    80001834:	8082                	ret

0000000080001836 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001836:	7139                	addi	sp,sp,-64
    80001838:	fc06                	sd	ra,56(sp)
    8000183a:	f822                	sd	s0,48(sp)
    8000183c:	f426                	sd	s1,40(sp)
    8000183e:	f04a                	sd	s2,32(sp)
    80001840:	ec4e                	sd	s3,24(sp)
    80001842:	e852                	sd	s4,16(sp)
    80001844:	e456                	sd	s5,8(sp)
    80001846:	e05a                	sd	s6,0(sp)
    80001848:	0080                	addi	s0,sp,64
    8000184a:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000184c:	0000f497          	auipc	s1,0xf
    80001850:	7e448493          	addi	s1,s1,2020 # 80011030 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001854:	8b26                	mv	s6,s1
    80001856:	00006a97          	auipc	s5,0x6
    8000185a:	7aaa8a93          	addi	s5,s5,1962 # 80008000 <etext>
    8000185e:	04000937          	lui	s2,0x4000
    80001862:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001864:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001866:	00015a17          	auipc	s4,0x15
    8000186a:	3caa0a13          	addi	s4,s4,970 # 80016c30 <tickslock>
    char *pa = kalloc();
    8000186e:	fffff097          	auipc	ra,0xfffff
    80001872:	278080e7          	jalr	632(ra) # 80000ae6 <kalloc>
    80001876:	862a                	mv	a2,a0
    if(pa == 0)
    80001878:	c131                	beqz	a0,800018bc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    8000187a:	416485b3          	sub	a1,s1,s6
    8000187e:	8591                	srai	a1,a1,0x4
    80001880:	000ab783          	ld	a5,0(s5)
    80001884:	02f585b3          	mul	a1,a1,a5
    80001888:	2585                	addiw	a1,a1,1
    8000188a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000188e:	4719                	li	a4,6
    80001890:	6685                	lui	a3,0x1
    80001892:	40b905b3          	sub	a1,s2,a1
    80001896:	854e                	mv	a0,s3
    80001898:	00000097          	auipc	ra,0x0
    8000189c:	8a6080e7          	jalr	-1882(ra) # 8000113e <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a0:	17048493          	addi	s1,s1,368
    800018a4:	fd4495e3          	bne	s1,s4,8000186e <proc_mapstacks+0x38>
  }
}
    800018a8:	70e2                	ld	ra,56(sp)
    800018aa:	7442                	ld	s0,48(sp)
    800018ac:	74a2                	ld	s1,40(sp)
    800018ae:	7902                	ld	s2,32(sp)
    800018b0:	69e2                	ld	s3,24(sp)
    800018b2:	6a42                	ld	s4,16(sp)
    800018b4:	6aa2                	ld	s5,8(sp)
    800018b6:	6b02                	ld	s6,0(sp)
    800018b8:	6121                	addi	sp,sp,64
    800018ba:	8082                	ret
      panic("kalloc");
    800018bc:	00007517          	auipc	a0,0x7
    800018c0:	91c50513          	addi	a0,a0,-1764 # 800081d8 <digits+0x198>
    800018c4:	fffff097          	auipc	ra,0xfffff
    800018c8:	c7c080e7          	jalr	-900(ra) # 80000540 <panic>

00000000800018cc <procinit>:

// initialize the proc table.
void
procinit(void)
{
    800018cc:	7139                	addi	sp,sp,-64
    800018ce:	fc06                	sd	ra,56(sp)
    800018d0:	f822                	sd	s0,48(sp)
    800018d2:	f426                	sd	s1,40(sp)
    800018d4:	f04a                	sd	s2,32(sp)
    800018d6:	ec4e                	sd	s3,24(sp)
    800018d8:	e852                	sd	s4,16(sp)
    800018da:	e456                	sd	s5,8(sp)
    800018dc:	e05a                	sd	s6,0(sp)
    800018de:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018e0:	00007597          	auipc	a1,0x7
    800018e4:	90058593          	addi	a1,a1,-1792 # 800081e0 <digits+0x1a0>
    800018e8:	0000f517          	auipc	a0,0xf
    800018ec:	31850513          	addi	a0,a0,792 # 80010c00 <pid_lock>
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	256080e7          	jalr	598(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f8:	00007597          	auipc	a1,0x7
    800018fc:	8f058593          	addi	a1,a1,-1808 # 800081e8 <digits+0x1a8>
    80001900:	0000f517          	auipc	a0,0xf
    80001904:	31850513          	addi	a0,a0,792 # 80010c18 <wait_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	23e080e7          	jalr	574(ra) # 80000b46 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001910:	0000f497          	auipc	s1,0xf
    80001914:	72048493          	addi	s1,s1,1824 # 80011030 <proc>
      initlock(&p->lock, "proc");
    80001918:	00007b17          	auipc	s6,0x7
    8000191c:	8e0b0b13          	addi	s6,s6,-1824 # 800081f8 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001920:	8aa6                	mv	s5,s1
    80001922:	00006a17          	auipc	s4,0x6
    80001926:	6dea0a13          	addi	s4,s4,1758 # 80008000 <etext>
    8000192a:	04000937          	lui	s2,0x4000
    8000192e:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001930:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001932:	00015997          	auipc	s3,0x15
    80001936:	2fe98993          	addi	s3,s3,766 # 80016c30 <tickslock>
      initlock(&p->lock, "proc");
    8000193a:	85da                	mv	a1,s6
    8000193c:	8526                	mv	a0,s1
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	208080e7          	jalr	520(ra) # 80000b46 <initlock>
      p->state = UNUSED;
    80001946:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    8000194a:	415487b3          	sub	a5,s1,s5
    8000194e:	8791                	srai	a5,a5,0x4
    80001950:	000a3703          	ld	a4,0(s4)
    80001954:	02e787b3          	mul	a5,a5,a4
    80001958:	2785                	addiw	a5,a5,1
    8000195a:	00d7979b          	slliw	a5,a5,0xd
    8000195e:	40f907b3          	sub	a5,s2,a5
    80001962:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001964:	17048493          	addi	s1,s1,368
    80001968:	fd3499e3          	bne	s1,s3,8000193a <procinit+0x6e>
  }
}
    8000196c:	70e2                	ld	ra,56(sp)
    8000196e:	7442                	ld	s0,48(sp)
    80001970:	74a2                	ld	s1,40(sp)
    80001972:	7902                	ld	s2,32(sp)
    80001974:	69e2                	ld	s3,24(sp)
    80001976:	6a42                	ld	s4,16(sp)
    80001978:	6aa2                	ld	s5,8(sp)
    8000197a:	6b02                	ld	s6,0(sp)
    8000197c:	6121                	addi	sp,sp,64
    8000197e:	8082                	ret

0000000080001980 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001980:	1141                	addi	sp,sp,-16
    80001982:	e422                	sd	s0,8(sp)
    80001984:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001986:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001988:	2501                	sext.w	a0,a0
    8000198a:	6422                	ld	s0,8(sp)
    8000198c:	0141                	addi	sp,sp,16
    8000198e:	8082                	ret

0000000080001990 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001990:	1141                	addi	sp,sp,-16
    80001992:	e422                	sd	s0,8(sp)
    80001994:	0800                	addi	s0,sp,16
    80001996:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001998:	2781                	sext.w	a5,a5
    8000199a:	079e                	slli	a5,a5,0x7
  return c;
}
    8000199c:	0000f517          	auipc	a0,0xf
    800019a0:	29450513          	addi	a0,a0,660 # 80010c30 <cpus>
    800019a4:	953e                	add	a0,a0,a5
    800019a6:	6422                	ld	s0,8(sp)
    800019a8:	0141                	addi	sp,sp,16
    800019aa:	8082                	ret

00000000800019ac <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    800019ac:	1101                	addi	sp,sp,-32
    800019ae:	ec06                	sd	ra,24(sp)
    800019b0:	e822                	sd	s0,16(sp)
    800019b2:	e426                	sd	s1,8(sp)
    800019b4:	1000                	addi	s0,sp,32
  push_off();
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	1d4080e7          	jalr	468(ra) # 80000b8a <push_off>
    800019be:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c0:	2781                	sext.w	a5,a5
    800019c2:	079e                	slli	a5,a5,0x7
    800019c4:	0000f717          	auipc	a4,0xf
    800019c8:	23c70713          	addi	a4,a4,572 # 80010c00 <pid_lock>
    800019cc:	97ba                	add	a5,a5,a4
    800019ce:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	25a080e7          	jalr	602(ra) # 80000c2a <pop_off>
  return p;
}
    800019d8:	8526                	mv	a0,s1
    800019da:	60e2                	ld	ra,24(sp)
    800019dc:	6442                	ld	s0,16(sp)
    800019de:	64a2                	ld	s1,8(sp)
    800019e0:	6105                	addi	sp,sp,32
    800019e2:	8082                	ret

00000000800019e4 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019e4:	1141                	addi	sp,sp,-16
    800019e6:	e406                	sd	ra,8(sp)
    800019e8:	e022                	sd	s0,0(sp)
    800019ea:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019ec:	00000097          	auipc	ra,0x0
    800019f0:	fc0080e7          	jalr	-64(ra) # 800019ac <myproc>
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	296080e7          	jalr	662(ra) # 80000c8a <release>

  if (first) {
    800019fc:	00007797          	auipc	a5,0x7
    80001a00:	ef47a783          	lw	a5,-268(a5) # 800088f0 <first.1>
    80001a04:	eb89                	bnez	a5,80001a16 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a06:	00001097          	auipc	ra,0x1
    80001a0a:	dd0080e7          	jalr	-560(ra) # 800027d6 <usertrapret>
}
    80001a0e:	60a2                	ld	ra,8(sp)
    80001a10:	6402                	ld	s0,0(sp)
    80001a12:	0141                	addi	sp,sp,16
    80001a14:	8082                	ret
    first = 0;
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	ec07ad23          	sw	zero,-294(a5) # 800088f0 <first.1>
    fsinit(ROOTDEV);
    80001a1e:	4505                	li	a0,1
    80001a20:	00002097          	auipc	ra,0x2
    80001a24:	b66080e7          	jalr	-1178(ra) # 80003586 <fsinit>
    80001a28:	bff9                	j	80001a06 <forkret+0x22>

0000000080001a2a <allocpid>:
{
    80001a2a:	1101                	addi	sp,sp,-32
    80001a2c:	ec06                	sd	ra,24(sp)
    80001a2e:	e822                	sd	s0,16(sp)
    80001a30:	e426                	sd	s1,8(sp)
    80001a32:	e04a                	sd	s2,0(sp)
    80001a34:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a36:	0000f917          	auipc	s2,0xf
    80001a3a:	1ca90913          	addi	s2,s2,458 # 80010c00 <pid_lock>
    80001a3e:	854a                	mv	a0,s2
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	196080e7          	jalr	406(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a48:	00007797          	auipc	a5,0x7
    80001a4c:	eac78793          	addi	a5,a5,-340 # 800088f4 <nextpid>
    80001a50:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a52:	0014871b          	addiw	a4,s1,1
    80001a56:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	230080e7          	jalr	560(ra) # 80000c8a <release>
}
    80001a62:	8526                	mv	a0,s1
    80001a64:	60e2                	ld	ra,24(sp)
    80001a66:	6442                	ld	s0,16(sp)
    80001a68:	64a2                	ld	s1,8(sp)
    80001a6a:	6902                	ld	s2,0(sp)
    80001a6c:	6105                	addi	sp,sp,32
    80001a6e:	8082                	ret

0000000080001a70 <proc_pagetable>:
{
    80001a70:	1101                	addi	sp,sp,-32
    80001a72:	ec06                	sd	ra,24(sp)
    80001a74:	e822                	sd	s0,16(sp)
    80001a76:	e426                	sd	s1,8(sp)
    80001a78:	e04a                	sd	s2,0(sp)
    80001a7a:	1000                	addi	s0,sp,32
    80001a7c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a7e:	00000097          	auipc	ra,0x0
    80001a82:	8aa080e7          	jalr	-1878(ra) # 80001328 <uvmcreate>
    80001a86:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a88:	c121                	beqz	a0,80001ac8 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8a:	4729                	li	a4,10
    80001a8c:	00005697          	auipc	a3,0x5
    80001a90:	57468693          	addi	a3,a3,1396 # 80007000 <_trampoline>
    80001a94:	6605                	lui	a2,0x1
    80001a96:	040005b7          	lui	a1,0x4000
    80001a9a:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a9c:	05b2                	slli	a1,a1,0xc
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	600080e7          	jalr	1536(ra) # 8000109e <mappages>
    80001aa6:	02054863          	bltz	a0,80001ad6 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aaa:	4719                	li	a4,6
    80001aac:	05893683          	ld	a3,88(s2)
    80001ab0:	6605                	lui	a2,0x1
    80001ab2:	020005b7          	lui	a1,0x2000
    80001ab6:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ab8:	05b6                	slli	a1,a1,0xd
    80001aba:	8526                	mv	a0,s1
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	5e2080e7          	jalr	1506(ra) # 8000109e <mappages>
    80001ac4:	02054163          	bltz	a0,80001ae6 <proc_pagetable+0x76>
}
    80001ac8:	8526                	mv	a0,s1
    80001aca:	60e2                	ld	ra,24(sp)
    80001acc:	6442                	ld	s0,16(sp)
    80001ace:	64a2                	ld	s1,8(sp)
    80001ad0:	6902                	ld	s2,0(sp)
    80001ad2:	6105                	addi	sp,sp,32
    80001ad4:	8082                	ret
    uvmfree(pagetable, 0);
    80001ad6:	4581                	li	a1,0
    80001ad8:	8526                	mv	a0,s1
    80001ada:	00000097          	auipc	ra,0x0
    80001ade:	a54080e7          	jalr	-1452(ra) # 8000152e <uvmfree>
    return 0;
    80001ae2:	4481                	li	s1,0
    80001ae4:	b7d5                	j	80001ac8 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ae6:	4681                	li	a3,0
    80001ae8:	4605                	li	a2,1
    80001aea:	040005b7          	lui	a1,0x4000
    80001aee:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001af0:	05b2                	slli	a1,a1,0xc
    80001af2:	8526                	mv	a0,s1
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	770080e7          	jalr	1904(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001afc:	4581                	li	a1,0
    80001afe:	8526                	mv	a0,s1
    80001b00:	00000097          	auipc	ra,0x0
    80001b04:	a2e080e7          	jalr	-1490(ra) # 8000152e <uvmfree>
    return 0;
    80001b08:	4481                	li	s1,0
    80001b0a:	bf7d                	j	80001ac8 <proc_pagetable+0x58>

0000000080001b0c <proc_freepagetable>:
{
    80001b0c:	1101                	addi	sp,sp,-32
    80001b0e:	ec06                	sd	ra,24(sp)
    80001b10:	e822                	sd	s0,16(sp)
    80001b12:	e426                	sd	s1,8(sp)
    80001b14:	e04a                	sd	s2,0(sp)
    80001b16:	1000                	addi	s0,sp,32
    80001b18:	84aa                	mv	s1,a0
    80001b1a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b1c:	4681                	li	a3,0
    80001b1e:	4605                	li	a2,1
    80001b20:	040005b7          	lui	a1,0x4000
    80001b24:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b26:	05b2                	slli	a1,a1,0xc
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	73c080e7          	jalr	1852(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b30:	4681                	li	a3,0
    80001b32:	4605                	li	a2,1
    80001b34:	020005b7          	lui	a1,0x2000
    80001b38:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b3a:	05b6                	slli	a1,a1,0xd
    80001b3c:	8526                	mv	a0,s1
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	726080e7          	jalr	1830(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b46:	85ca                	mv	a1,s2
    80001b48:	8526                	mv	a0,s1
    80001b4a:	00000097          	auipc	ra,0x0
    80001b4e:	9e4080e7          	jalr	-1564(ra) # 8000152e <uvmfree>
}
    80001b52:	60e2                	ld	ra,24(sp)
    80001b54:	6442                	ld	s0,16(sp)
    80001b56:	64a2                	ld	s1,8(sp)
    80001b58:	6902                	ld	s2,0(sp)
    80001b5a:	6105                	addi	sp,sp,32
    80001b5c:	8082                	ret

0000000080001b5e <freeproc>:
{
    80001b5e:	1101                	addi	sp,sp,-32
    80001b60:	ec06                	sd	ra,24(sp)
    80001b62:	e822                	sd	s0,16(sp)
    80001b64:	e426                	sd	s1,8(sp)
    80001b66:	1000                	addi	s0,sp,32
    80001b68:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b6a:	6d28                	ld	a0,88(a0)
    80001b6c:	c509                	beqz	a0,80001b76 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b6e:	fffff097          	auipc	ra,0xfffff
    80001b72:	e7a080e7          	jalr	-390(ra) # 800009e8 <kfree>
  p->trapframe = 0;
    80001b76:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b7a:	68a8                	ld	a0,80(s1)
    80001b7c:	c511                	beqz	a0,80001b88 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b7e:	64ac                	ld	a1,72(s1)
    80001b80:	00000097          	auipc	ra,0x0
    80001b84:	f8c080e7          	jalr	-116(ra) # 80001b0c <proc_freepagetable>
  p->pagetable = 0;
    80001b88:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b8c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b90:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b94:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b98:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b9c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba0:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba4:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ba8:	0004ac23          	sw	zero,24(s1)
}
    80001bac:	60e2                	ld	ra,24(sp)
    80001bae:	6442                	ld	s0,16(sp)
    80001bb0:	64a2                	ld	s1,8(sp)
    80001bb2:	6105                	addi	sp,sp,32
    80001bb4:	8082                	ret

0000000080001bb6 <allocproc>:
{
    80001bb6:	1101                	addi	sp,sp,-32
    80001bb8:	ec06                	sd	ra,24(sp)
    80001bba:	e822                	sd	s0,16(sp)
    80001bbc:	e426                	sd	s1,8(sp)
    80001bbe:	e04a                	sd	s2,0(sp)
    80001bc0:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bc2:	0000f497          	auipc	s1,0xf
    80001bc6:	46e48493          	addi	s1,s1,1134 # 80011030 <proc>
    80001bca:	00015917          	auipc	s2,0x15
    80001bce:	06690913          	addi	s2,s2,102 # 80016c30 <tickslock>
    acquire(&p->lock);
    80001bd2:	8526                	mv	a0,s1
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	002080e7          	jalr	2(ra) # 80000bd6 <acquire>
    if(p->state == UNUSED) {
    80001bdc:	4c9c                	lw	a5,24(s1)
    80001bde:	cf81                	beqz	a5,80001bf6 <allocproc+0x40>
      release(&p->lock);
    80001be0:	8526                	mv	a0,s1
    80001be2:	fffff097          	auipc	ra,0xfffff
    80001be6:	0a8080e7          	jalr	168(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bea:	17048493          	addi	s1,s1,368
    80001bee:	ff2492e3          	bne	s1,s2,80001bd2 <allocproc+0x1c>
  return 0;
    80001bf2:	4481                	li	s1,0
    80001bf4:	a8a1                	j	80001c4c <allocproc+0x96>
  p->pid = allocpid();
    80001bf6:	00000097          	auipc	ra,0x0
    80001bfa:	e34080e7          	jalr	-460(ra) # 80001a2a <allocpid>
    80001bfe:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c00:	4785                	li	a5,1
    80001c02:	cc9c                	sw	a5,24(s1)
  p->priority = 10;
    80001c04:	47a9                	li	a5,10
    80001c06:	16f4a423          	sw	a5,360(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c0a:	fffff097          	auipc	ra,0xfffff
    80001c0e:	edc080e7          	jalr	-292(ra) # 80000ae6 <kalloc>
    80001c12:	892a                	mv	s2,a0
    80001c14:	eca8                	sd	a0,88(s1)
    80001c16:	c131                	beqz	a0,80001c5a <allocproc+0xa4>
  p->pagetable = proc_pagetable(p);
    80001c18:	8526                	mv	a0,s1
    80001c1a:	00000097          	auipc	ra,0x0
    80001c1e:	e56080e7          	jalr	-426(ra) # 80001a70 <proc_pagetable>
    80001c22:	892a                	mv	s2,a0
    80001c24:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c26:	c531                	beqz	a0,80001c72 <allocproc+0xbc>
  memset(&p->context, 0, sizeof(p->context));
    80001c28:	07000613          	li	a2,112
    80001c2c:	4581                	li	a1,0
    80001c2e:	06048513          	addi	a0,s1,96
    80001c32:	fffff097          	auipc	ra,0xfffff
    80001c36:	0a0080e7          	jalr	160(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c3a:	00000797          	auipc	a5,0x0
    80001c3e:	daa78793          	addi	a5,a5,-598 # 800019e4 <forkret>
    80001c42:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c44:	60bc                	ld	a5,64(s1)
    80001c46:	6705                	lui	a4,0x1
    80001c48:	97ba                	add	a5,a5,a4
    80001c4a:	f4bc                	sd	a5,104(s1)
}
    80001c4c:	8526                	mv	a0,s1
    80001c4e:	60e2                	ld	ra,24(sp)
    80001c50:	6442                	ld	s0,16(sp)
    80001c52:	64a2                	ld	s1,8(sp)
    80001c54:	6902                	ld	s2,0(sp)
    80001c56:	6105                	addi	sp,sp,32
    80001c58:	8082                	ret
    freeproc(p);
    80001c5a:	8526                	mv	a0,s1
    80001c5c:	00000097          	auipc	ra,0x0
    80001c60:	f02080e7          	jalr	-254(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c64:	8526                	mv	a0,s1
    80001c66:	fffff097          	auipc	ra,0xfffff
    80001c6a:	024080e7          	jalr	36(ra) # 80000c8a <release>
    return 0;
    80001c6e:	84ca                	mv	s1,s2
    80001c70:	bff1                	j	80001c4c <allocproc+0x96>
    freeproc(p);
    80001c72:	8526                	mv	a0,s1
    80001c74:	00000097          	auipc	ra,0x0
    80001c78:	eea080e7          	jalr	-278(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c7c:	8526                	mv	a0,s1
    80001c7e:	fffff097          	auipc	ra,0xfffff
    80001c82:	00c080e7          	jalr	12(ra) # 80000c8a <release>
    return 0;
    80001c86:	84ca                	mv	s1,s2
    80001c88:	b7d1                	j	80001c4c <allocproc+0x96>

0000000080001c8a <userinit>:
{
    80001c8a:	1101                	addi	sp,sp,-32
    80001c8c:	ec06                	sd	ra,24(sp)
    80001c8e:	e822                	sd	s0,16(sp)
    80001c90:	e426                	sd	s1,8(sp)
    80001c92:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c94:	00000097          	auipc	ra,0x0
    80001c98:	f22080e7          	jalr	-222(ra) # 80001bb6 <allocproc>
    80001c9c:	84aa                	mv	s1,a0
  initproc = p;
    80001c9e:	00007797          	auipc	a5,0x7
    80001ca2:	cea7b523          	sd	a0,-790(a5) # 80008988 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001ca6:	03400613          	li	a2,52
    80001caa:	00007597          	auipc	a1,0x7
    80001cae:	c5658593          	addi	a1,a1,-938 # 80008900 <initcode>
    80001cb2:	6928                	ld	a0,80(a0)
    80001cb4:	fffff097          	auipc	ra,0xfffff
    80001cb8:	6a2080e7          	jalr	1698(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001cbc:	6785                	lui	a5,0x1
    80001cbe:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cc0:	6cb8                	ld	a4,88(s1)
    80001cc2:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cc6:	6cb8                	ld	a4,88(s1)
    80001cc8:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cca:	4641                	li	a2,16
    80001ccc:	00006597          	auipc	a1,0x6
    80001cd0:	53458593          	addi	a1,a1,1332 # 80008200 <digits+0x1c0>
    80001cd4:	15848513          	addi	a0,s1,344
    80001cd8:	fffff097          	auipc	ra,0xfffff
    80001cdc:	144080e7          	jalr	324(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001ce0:	00006517          	auipc	a0,0x6
    80001ce4:	53050513          	addi	a0,a0,1328 # 80008210 <digits+0x1d0>
    80001ce8:	00002097          	auipc	ra,0x2
    80001cec:	2c8080e7          	jalr	712(ra) # 80003fb0 <namei>
    80001cf0:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cf4:	478d                	li	a5,3
    80001cf6:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cf8:	8526                	mv	a0,s1
    80001cfa:	fffff097          	auipc	ra,0xfffff
    80001cfe:	f90080e7          	jalr	-112(ra) # 80000c8a <release>
}
    80001d02:	60e2                	ld	ra,24(sp)
    80001d04:	6442                	ld	s0,16(sp)
    80001d06:	64a2                	ld	s1,8(sp)
    80001d08:	6105                	addi	sp,sp,32
    80001d0a:	8082                	ret

0000000080001d0c <growproc>:
{
    80001d0c:	1101                	addi	sp,sp,-32
    80001d0e:	ec06                	sd	ra,24(sp)
    80001d10:	e822                	sd	s0,16(sp)
    80001d12:	e426                	sd	s1,8(sp)
    80001d14:	e04a                	sd	s2,0(sp)
    80001d16:	1000                	addi	s0,sp,32
    80001d18:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d1a:	00000097          	auipc	ra,0x0
    80001d1e:	c92080e7          	jalr	-878(ra) # 800019ac <myproc>
    80001d22:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d24:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d26:	01204c63          	bgtz	s2,80001d3e <growproc+0x32>
  } else if(n < 0){
    80001d2a:	02094663          	bltz	s2,80001d56 <growproc+0x4a>
  p->sz = sz;
    80001d2e:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d30:	4501                	li	a0,0
}
    80001d32:	60e2                	ld	ra,24(sp)
    80001d34:	6442                	ld	s0,16(sp)
    80001d36:	64a2                	ld	s1,8(sp)
    80001d38:	6902                	ld	s2,0(sp)
    80001d3a:	6105                	addi	sp,sp,32
    80001d3c:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001d3e:	4691                	li	a3,4
    80001d40:	00b90633          	add	a2,s2,a1
    80001d44:	6928                	ld	a0,80(a0)
    80001d46:	fffff097          	auipc	ra,0xfffff
    80001d4a:	6ca080e7          	jalr	1738(ra) # 80001410 <uvmalloc>
    80001d4e:	85aa                	mv	a1,a0
    80001d50:	fd79                	bnez	a0,80001d2e <growproc+0x22>
      return -1;
    80001d52:	557d                	li	a0,-1
    80001d54:	bff9                	j	80001d32 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d56:	00b90633          	add	a2,s2,a1
    80001d5a:	6928                	ld	a0,80(a0)
    80001d5c:	fffff097          	auipc	ra,0xfffff
    80001d60:	66c080e7          	jalr	1644(ra) # 800013c8 <uvmdealloc>
    80001d64:	85aa                	mv	a1,a0
    80001d66:	b7e1                	j	80001d2e <growproc+0x22>

0000000080001d68 <fork>:
{
    80001d68:	7139                	addi	sp,sp,-64
    80001d6a:	fc06                	sd	ra,56(sp)
    80001d6c:	f822                	sd	s0,48(sp)
    80001d6e:	f426                	sd	s1,40(sp)
    80001d70:	f04a                	sd	s2,32(sp)
    80001d72:	ec4e                	sd	s3,24(sp)
    80001d74:	e852                	sd	s4,16(sp)
    80001d76:	e456                	sd	s5,8(sp)
    80001d78:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d7a:	00000097          	auipc	ra,0x0
    80001d7e:	c32080e7          	jalr	-974(ra) # 800019ac <myproc>
    80001d82:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001d84:	00000097          	auipc	ra,0x0
    80001d88:	e32080e7          	jalr	-462(ra) # 80001bb6 <allocproc>
    80001d8c:	10050c63          	beqz	a0,80001ea4 <fork+0x13c>
    80001d90:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001d92:	048ab603          	ld	a2,72(s5)
    80001d96:	692c                	ld	a1,80(a0)
    80001d98:	050ab503          	ld	a0,80(s5)
    80001d9c:	fffff097          	auipc	ra,0xfffff
    80001da0:	7cc080e7          	jalr	1996(ra) # 80001568 <uvmcopy>
    80001da4:	04054863          	bltz	a0,80001df4 <fork+0x8c>
  np->sz = p->sz;
    80001da8:	048ab783          	ld	a5,72(s5)
    80001dac:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001db0:	058ab683          	ld	a3,88(s5)
    80001db4:	87b6                	mv	a5,a3
    80001db6:	058a3703          	ld	a4,88(s4)
    80001dba:	12068693          	addi	a3,a3,288
    80001dbe:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dc2:	6788                	ld	a0,8(a5)
    80001dc4:	6b8c                	ld	a1,16(a5)
    80001dc6:	6f90                	ld	a2,24(a5)
    80001dc8:	01073023          	sd	a6,0(a4)
    80001dcc:	e708                	sd	a0,8(a4)
    80001dce:	eb0c                	sd	a1,16(a4)
    80001dd0:	ef10                	sd	a2,24(a4)
    80001dd2:	02078793          	addi	a5,a5,32
    80001dd6:	02070713          	addi	a4,a4,32
    80001dda:	fed792e3          	bne	a5,a3,80001dbe <fork+0x56>
  np->trapframe->a0 = 0;
    80001dde:	058a3783          	ld	a5,88(s4)
    80001de2:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001de6:	0d0a8493          	addi	s1,s5,208
    80001dea:	0d0a0913          	addi	s2,s4,208
    80001dee:	150a8993          	addi	s3,s5,336
    80001df2:	a00d                	j	80001e14 <fork+0xac>
    freeproc(np);
    80001df4:	8552                	mv	a0,s4
    80001df6:	00000097          	auipc	ra,0x0
    80001dfa:	d68080e7          	jalr	-664(ra) # 80001b5e <freeproc>
    release(&np->lock);
    80001dfe:	8552                	mv	a0,s4
    80001e00:	fffff097          	auipc	ra,0xfffff
    80001e04:	e8a080e7          	jalr	-374(ra) # 80000c8a <release>
    return -1;
    80001e08:	597d                	li	s2,-1
    80001e0a:	a059                	j	80001e90 <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001e0c:	04a1                	addi	s1,s1,8
    80001e0e:	0921                	addi	s2,s2,8
    80001e10:	01348b63          	beq	s1,s3,80001e26 <fork+0xbe>
    if(p->ofile[i])
    80001e14:	6088                	ld	a0,0(s1)
    80001e16:	d97d                	beqz	a0,80001e0c <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e18:	00003097          	auipc	ra,0x3
    80001e1c:	82e080e7          	jalr	-2002(ra) # 80004646 <filedup>
    80001e20:	00a93023          	sd	a0,0(s2)
    80001e24:	b7e5                	j	80001e0c <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e26:	150ab503          	ld	a0,336(s5)
    80001e2a:	00002097          	auipc	ra,0x2
    80001e2e:	99c080e7          	jalr	-1636(ra) # 800037c6 <idup>
    80001e32:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e36:	4641                	li	a2,16
    80001e38:	158a8593          	addi	a1,s5,344
    80001e3c:	158a0513          	addi	a0,s4,344
    80001e40:	fffff097          	auipc	ra,0xfffff
    80001e44:	fdc080e7          	jalr	-36(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001e48:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e4c:	8552                	mv	a0,s4
    80001e4e:	fffff097          	auipc	ra,0xfffff
    80001e52:	e3c080e7          	jalr	-452(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001e56:	0000f497          	auipc	s1,0xf
    80001e5a:	dc248493          	addi	s1,s1,-574 # 80010c18 <wait_lock>
    80001e5e:	8526                	mv	a0,s1
    80001e60:	fffff097          	auipc	ra,0xfffff
    80001e64:	d76080e7          	jalr	-650(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001e68:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e6c:	8526                	mv	a0,s1
    80001e6e:	fffff097          	auipc	ra,0xfffff
    80001e72:	e1c080e7          	jalr	-484(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001e76:	8552                	mv	a0,s4
    80001e78:	fffff097          	auipc	ra,0xfffff
    80001e7c:	d5e080e7          	jalr	-674(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001e80:	478d                	li	a5,3
    80001e82:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001e86:	8552                	mv	a0,s4
    80001e88:	fffff097          	auipc	ra,0xfffff
    80001e8c:	e02080e7          	jalr	-510(ra) # 80000c8a <release>
}
    80001e90:	854a                	mv	a0,s2
    80001e92:	70e2                	ld	ra,56(sp)
    80001e94:	7442                	ld	s0,48(sp)
    80001e96:	74a2                	ld	s1,40(sp)
    80001e98:	7902                	ld	s2,32(sp)
    80001e9a:	69e2                	ld	s3,24(sp)
    80001e9c:	6a42                	ld	s4,16(sp)
    80001e9e:	6aa2                	ld	s5,8(sp)
    80001ea0:	6121                	addi	sp,sp,64
    80001ea2:	8082                	ret
    return -1;
    80001ea4:	597d                	li	s2,-1
    80001ea6:	b7ed                	j	80001e90 <fork+0x128>

0000000080001ea8 <scheduler>:
{
    80001ea8:	715d                	addi	sp,sp,-80
    80001eaa:	e486                	sd	ra,72(sp)
    80001eac:	e0a2                	sd	s0,64(sp)
    80001eae:	fc26                	sd	s1,56(sp)
    80001eb0:	f84a                	sd	s2,48(sp)
    80001eb2:	f44e                	sd	s3,40(sp)
    80001eb4:	f052                	sd	s4,32(sp)
    80001eb6:	ec56                	sd	s5,24(sp)
    80001eb8:	e85a                	sd	s6,16(sp)
    80001eba:	e45e                	sd	s7,8(sp)
    80001ebc:	0880                	addi	s0,sp,80
    80001ebe:	8792                	mv	a5,tp
  int id = r_tp();
    80001ec0:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ec2:	00779b13          	slli	s6,a5,0x7
    80001ec6:	0000f717          	auipc	a4,0xf
    80001eca:	d3a70713          	addi	a4,a4,-710 # 80010c00 <pid_lock>
    80001ece:	975a                	add	a4,a4,s6
    80001ed0:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ed4:	0000f717          	auipc	a4,0xf
    80001ed8:	d6470713          	addi	a4,a4,-668 # 80010c38 <cpus+0x8>
    80001edc:	9b3a                	add	s6,s6,a4
      if(p->state == RUNNABLE) {
    80001ede:	4a0d                	li	s4,3
        p->state = RUNNING;
    80001ee0:	4b91                	li	s7,4
        c->proc = p;
    80001ee2:	079e                	slli	a5,a5,0x7
    80001ee4:	0000fa97          	auipc	s5,0xf
    80001ee8:	d1ca8a93          	addi	s5,s5,-740 # 80010c00 <pid_lock>
    80001eec:	9abe                	add	s5,s5,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001eee:	00015997          	auipc	s3,0x15
    80001ef2:	d4298993          	addi	s3,s3,-702 # 80016c30 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ef6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001efa:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001efe:	10079073          	csrw	sstatus,a5
    80001f02:	0000f497          	auipc	s1,0xf
    80001f06:	12e48493          	addi	s1,s1,302 # 80011030 <proc>
    80001f0a:	a03d                	j	80001f38 <scheduler+0x90>
        p->state = RUNNING;
    80001f0c:	0174ac23          	sw	s7,24(s1)
        c->proc = p;
    80001f10:	029ab823          	sd	s1,48(s5)
        swtch(&c->context, &p->context);
    80001f14:	06090593          	addi	a1,s2,96
    80001f18:	855a                	mv	a0,s6
    80001f1a:	00001097          	auipc	ra,0x1
    80001f1e:	812080e7          	jalr	-2030(ra) # 8000272c <swtch>
        c->proc = 0;
    80001f22:	020ab823          	sd	zero,48(s5)
    release(&p->lock);
    80001f26:	8526                	mv	a0,s1
    80001f28:	fffff097          	auipc	ra,0xfffff
    80001f2c:	d62080e7          	jalr	-670(ra) # 80000c8a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f30:	17048493          	addi	s1,s1,368
    80001f34:	fd3481e3          	beq	s1,s3,80001ef6 <scheduler+0x4e>
      acquire(&p->lock);
    80001f38:	8926                	mv	s2,s1
    80001f3a:	8526                	mv	a0,s1
    80001f3c:	fffff097          	auipc	ra,0xfffff
    80001f40:	c9a080e7          	jalr	-870(ra) # 80000bd6 <acquire>
      if(p->state == RUNNABLE) {
    80001f44:	4c9c                	lw	a5,24(s1)
    80001f46:	ff4790e3          	bne	a5,s4,80001f26 <scheduler+0x7e>
    80001f4a:	04000793          	li	a5,64
        for(p1 = proc; p1< &proc[NPROC]; p1++)
    80001f4e:	17fd                	addi	a5,a5,-1
    80001f50:	fffd                	bnez	a5,80001f4e <scheduler+0xa6>
    80001f52:	bf6d                	j	80001f0c <scheduler+0x64>

0000000080001f54 <sched>:
{
    80001f54:	7179                	addi	sp,sp,-48
    80001f56:	f406                	sd	ra,40(sp)
    80001f58:	f022                	sd	s0,32(sp)
    80001f5a:	ec26                	sd	s1,24(sp)
    80001f5c:	e84a                	sd	s2,16(sp)
    80001f5e:	e44e                	sd	s3,8(sp)
    80001f60:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f62:	00000097          	auipc	ra,0x0
    80001f66:	a4a080e7          	jalr	-1462(ra) # 800019ac <myproc>
    80001f6a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f6c:	fffff097          	auipc	ra,0xfffff
    80001f70:	bf0080e7          	jalr	-1040(ra) # 80000b5c <holding>
    80001f74:	c93d                	beqz	a0,80001fea <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f76:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f78:	2781                	sext.w	a5,a5
    80001f7a:	079e                	slli	a5,a5,0x7
    80001f7c:	0000f717          	auipc	a4,0xf
    80001f80:	c8470713          	addi	a4,a4,-892 # 80010c00 <pid_lock>
    80001f84:	97ba                	add	a5,a5,a4
    80001f86:	0a87a703          	lw	a4,168(a5)
    80001f8a:	4785                	li	a5,1
    80001f8c:	06f71763          	bne	a4,a5,80001ffa <sched+0xa6>
  if(p->state == RUNNING)
    80001f90:	4c98                	lw	a4,24(s1)
    80001f92:	4791                	li	a5,4
    80001f94:	06f70b63          	beq	a4,a5,8000200a <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f98:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f9c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f9e:	efb5                	bnez	a5,8000201a <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fa0:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fa2:	0000f917          	auipc	s2,0xf
    80001fa6:	c5e90913          	addi	s2,s2,-930 # 80010c00 <pid_lock>
    80001faa:	2781                	sext.w	a5,a5
    80001fac:	079e                	slli	a5,a5,0x7
    80001fae:	97ca                	add	a5,a5,s2
    80001fb0:	0ac7a983          	lw	s3,172(a5)
    80001fb4:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fb6:	2781                	sext.w	a5,a5
    80001fb8:	079e                	slli	a5,a5,0x7
    80001fba:	0000f597          	auipc	a1,0xf
    80001fbe:	c7e58593          	addi	a1,a1,-898 # 80010c38 <cpus+0x8>
    80001fc2:	95be                	add	a1,a1,a5
    80001fc4:	06048513          	addi	a0,s1,96
    80001fc8:	00000097          	auipc	ra,0x0
    80001fcc:	764080e7          	jalr	1892(ra) # 8000272c <swtch>
    80001fd0:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fd2:	2781                	sext.w	a5,a5
    80001fd4:	079e                	slli	a5,a5,0x7
    80001fd6:	993e                	add	s2,s2,a5
    80001fd8:	0b392623          	sw	s3,172(s2)
}
    80001fdc:	70a2                	ld	ra,40(sp)
    80001fde:	7402                	ld	s0,32(sp)
    80001fe0:	64e2                	ld	s1,24(sp)
    80001fe2:	6942                	ld	s2,16(sp)
    80001fe4:	69a2                	ld	s3,8(sp)
    80001fe6:	6145                	addi	sp,sp,48
    80001fe8:	8082                	ret
    panic("sched p->lock");
    80001fea:	00006517          	auipc	a0,0x6
    80001fee:	22e50513          	addi	a0,a0,558 # 80008218 <digits+0x1d8>
    80001ff2:	ffffe097          	auipc	ra,0xffffe
    80001ff6:	54e080e7          	jalr	1358(ra) # 80000540 <panic>
    panic("sched locks");
    80001ffa:	00006517          	auipc	a0,0x6
    80001ffe:	22e50513          	addi	a0,a0,558 # 80008228 <digits+0x1e8>
    80002002:	ffffe097          	auipc	ra,0xffffe
    80002006:	53e080e7          	jalr	1342(ra) # 80000540 <panic>
    panic("sched running");
    8000200a:	00006517          	auipc	a0,0x6
    8000200e:	22e50513          	addi	a0,a0,558 # 80008238 <digits+0x1f8>
    80002012:	ffffe097          	auipc	ra,0xffffe
    80002016:	52e080e7          	jalr	1326(ra) # 80000540 <panic>
    panic("sched interruptible");
    8000201a:	00006517          	auipc	a0,0x6
    8000201e:	22e50513          	addi	a0,a0,558 # 80008248 <digits+0x208>
    80002022:	ffffe097          	auipc	ra,0xffffe
    80002026:	51e080e7          	jalr	1310(ra) # 80000540 <panic>

000000008000202a <yield>:
{
    8000202a:	1101                	addi	sp,sp,-32
    8000202c:	ec06                	sd	ra,24(sp)
    8000202e:	e822                	sd	s0,16(sp)
    80002030:	e426                	sd	s1,8(sp)
    80002032:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002034:	00000097          	auipc	ra,0x0
    80002038:	978080e7          	jalr	-1672(ra) # 800019ac <myproc>
    8000203c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000203e:	fffff097          	auipc	ra,0xfffff
    80002042:	b98080e7          	jalr	-1128(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    80002046:	478d                	li	a5,3
    80002048:	cc9c                	sw	a5,24(s1)
  sched();
    8000204a:	00000097          	auipc	ra,0x0
    8000204e:	f0a080e7          	jalr	-246(ra) # 80001f54 <sched>
  release(&p->lock);
    80002052:	8526                	mv	a0,s1
    80002054:	fffff097          	auipc	ra,0xfffff
    80002058:	c36080e7          	jalr	-970(ra) # 80000c8a <release>
}
    8000205c:	60e2                	ld	ra,24(sp)
    8000205e:	6442                	ld	s0,16(sp)
    80002060:	64a2                	ld	s1,8(sp)
    80002062:	6105                	addi	sp,sp,32
    80002064:	8082                	ret

0000000080002066 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002066:	7179                	addi	sp,sp,-48
    80002068:	f406                	sd	ra,40(sp)
    8000206a:	f022                	sd	s0,32(sp)
    8000206c:	ec26                	sd	s1,24(sp)
    8000206e:	e84a                	sd	s2,16(sp)
    80002070:	e44e                	sd	s3,8(sp)
    80002072:	1800                	addi	s0,sp,48
    80002074:	89aa                	mv	s3,a0
    80002076:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002078:	00000097          	auipc	ra,0x0
    8000207c:	934080e7          	jalr	-1740(ra) # 800019ac <myproc>
    80002080:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002082:	fffff097          	auipc	ra,0xfffff
    80002086:	b54080e7          	jalr	-1196(ra) # 80000bd6 <acquire>
  release(lk);
    8000208a:	854a                	mv	a0,s2
    8000208c:	fffff097          	auipc	ra,0xfffff
    80002090:	bfe080e7          	jalr	-1026(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    80002094:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002098:	4789                	li	a5,2
    8000209a:	cc9c                	sw	a5,24(s1)

  sched();
    8000209c:	00000097          	auipc	ra,0x0
    800020a0:	eb8080e7          	jalr	-328(ra) # 80001f54 <sched>

  // Tidy up.
  p->chan = 0;
    800020a4:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020a8:	8526                	mv	a0,s1
    800020aa:	fffff097          	auipc	ra,0xfffff
    800020ae:	be0080e7          	jalr	-1056(ra) # 80000c8a <release>
  acquire(lk);
    800020b2:	854a                	mv	a0,s2
    800020b4:	fffff097          	auipc	ra,0xfffff
    800020b8:	b22080e7          	jalr	-1246(ra) # 80000bd6 <acquire>
}
    800020bc:	70a2                	ld	ra,40(sp)
    800020be:	7402                	ld	s0,32(sp)
    800020c0:	64e2                	ld	s1,24(sp)
    800020c2:	6942                	ld	s2,16(sp)
    800020c4:	69a2                	ld	s3,8(sp)
    800020c6:	6145                	addi	sp,sp,48
    800020c8:	8082                	ret

00000000800020ca <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800020ca:	7139                	addi	sp,sp,-64
    800020cc:	fc06                	sd	ra,56(sp)
    800020ce:	f822                	sd	s0,48(sp)
    800020d0:	f426                	sd	s1,40(sp)
    800020d2:	f04a                	sd	s2,32(sp)
    800020d4:	ec4e                	sd	s3,24(sp)
    800020d6:	e852                	sd	s4,16(sp)
    800020d8:	e456                	sd	s5,8(sp)
    800020da:	0080                	addi	s0,sp,64
    800020dc:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800020de:	0000f497          	auipc	s1,0xf
    800020e2:	f5248493          	addi	s1,s1,-174 # 80011030 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800020e6:	4989                	li	s3,2
        p->state = RUNNABLE;
    800020e8:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800020ea:	00015917          	auipc	s2,0x15
    800020ee:	b4690913          	addi	s2,s2,-1210 # 80016c30 <tickslock>
    800020f2:	a811                	j	80002106 <wakeup+0x3c>
      }
      release(&p->lock);
    800020f4:	8526                	mv	a0,s1
    800020f6:	fffff097          	auipc	ra,0xfffff
    800020fa:	b94080e7          	jalr	-1132(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800020fe:	17048493          	addi	s1,s1,368
    80002102:	03248663          	beq	s1,s2,8000212e <wakeup+0x64>
    if(p != myproc()){
    80002106:	00000097          	auipc	ra,0x0
    8000210a:	8a6080e7          	jalr	-1882(ra) # 800019ac <myproc>
    8000210e:	fea488e3          	beq	s1,a0,800020fe <wakeup+0x34>
      acquire(&p->lock);
    80002112:	8526                	mv	a0,s1
    80002114:	fffff097          	auipc	ra,0xfffff
    80002118:	ac2080e7          	jalr	-1342(ra) # 80000bd6 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000211c:	4c9c                	lw	a5,24(s1)
    8000211e:	fd379be3          	bne	a5,s3,800020f4 <wakeup+0x2a>
    80002122:	709c                	ld	a5,32(s1)
    80002124:	fd4798e3          	bne	a5,s4,800020f4 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002128:	0154ac23          	sw	s5,24(s1)
    8000212c:	b7e1                	j	800020f4 <wakeup+0x2a>
    }
  }
}
    8000212e:	70e2                	ld	ra,56(sp)
    80002130:	7442                	ld	s0,48(sp)
    80002132:	74a2                	ld	s1,40(sp)
    80002134:	7902                	ld	s2,32(sp)
    80002136:	69e2                	ld	s3,24(sp)
    80002138:	6a42                	ld	s4,16(sp)
    8000213a:	6aa2                	ld	s5,8(sp)
    8000213c:	6121                	addi	sp,sp,64
    8000213e:	8082                	ret

0000000080002140 <reparent>:
{
    80002140:	7179                	addi	sp,sp,-48
    80002142:	f406                	sd	ra,40(sp)
    80002144:	f022                	sd	s0,32(sp)
    80002146:	ec26                	sd	s1,24(sp)
    80002148:	e84a                	sd	s2,16(sp)
    8000214a:	e44e                	sd	s3,8(sp)
    8000214c:	e052                	sd	s4,0(sp)
    8000214e:	1800                	addi	s0,sp,48
    80002150:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002152:	0000f497          	auipc	s1,0xf
    80002156:	ede48493          	addi	s1,s1,-290 # 80011030 <proc>
      pp->parent = initproc;
    8000215a:	00007a17          	auipc	s4,0x7
    8000215e:	82ea0a13          	addi	s4,s4,-2002 # 80008988 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002162:	00015997          	auipc	s3,0x15
    80002166:	ace98993          	addi	s3,s3,-1330 # 80016c30 <tickslock>
    8000216a:	a029                	j	80002174 <reparent+0x34>
    8000216c:	17048493          	addi	s1,s1,368
    80002170:	01348d63          	beq	s1,s3,8000218a <reparent+0x4a>
    if(pp->parent == p){
    80002174:	7c9c                	ld	a5,56(s1)
    80002176:	ff279be3          	bne	a5,s2,8000216c <reparent+0x2c>
      pp->parent = initproc;
    8000217a:	000a3503          	ld	a0,0(s4)
    8000217e:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002180:	00000097          	auipc	ra,0x0
    80002184:	f4a080e7          	jalr	-182(ra) # 800020ca <wakeup>
    80002188:	b7d5                	j	8000216c <reparent+0x2c>
}
    8000218a:	70a2                	ld	ra,40(sp)
    8000218c:	7402                	ld	s0,32(sp)
    8000218e:	64e2                	ld	s1,24(sp)
    80002190:	6942                	ld	s2,16(sp)
    80002192:	69a2                	ld	s3,8(sp)
    80002194:	6a02                	ld	s4,0(sp)
    80002196:	6145                	addi	sp,sp,48
    80002198:	8082                	ret

000000008000219a <exit>:
{
    8000219a:	7179                	addi	sp,sp,-48
    8000219c:	f406                	sd	ra,40(sp)
    8000219e:	f022                	sd	s0,32(sp)
    800021a0:	ec26                	sd	s1,24(sp)
    800021a2:	e84a                	sd	s2,16(sp)
    800021a4:	e44e                	sd	s3,8(sp)
    800021a6:	e052                	sd	s4,0(sp)
    800021a8:	1800                	addi	s0,sp,48
    800021aa:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800021ac:	00000097          	auipc	ra,0x0
    800021b0:	800080e7          	jalr	-2048(ra) # 800019ac <myproc>
    800021b4:	89aa                	mv	s3,a0
  if(p == initproc)
    800021b6:	00006797          	auipc	a5,0x6
    800021ba:	7d27b783          	ld	a5,2002(a5) # 80008988 <initproc>
    800021be:	0d050493          	addi	s1,a0,208
    800021c2:	15050913          	addi	s2,a0,336
    800021c6:	02a79363          	bne	a5,a0,800021ec <exit+0x52>
    panic("init exiting");
    800021ca:	00006517          	auipc	a0,0x6
    800021ce:	09650513          	addi	a0,a0,150 # 80008260 <digits+0x220>
    800021d2:	ffffe097          	auipc	ra,0xffffe
    800021d6:	36e080e7          	jalr	878(ra) # 80000540 <panic>
      fileclose(f);
    800021da:	00002097          	auipc	ra,0x2
    800021de:	4be080e7          	jalr	1214(ra) # 80004698 <fileclose>
      p->ofile[fd] = 0;
    800021e2:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800021e6:	04a1                	addi	s1,s1,8
    800021e8:	01248563          	beq	s1,s2,800021f2 <exit+0x58>
    if(p->ofile[fd]){
    800021ec:	6088                	ld	a0,0(s1)
    800021ee:	f575                	bnez	a0,800021da <exit+0x40>
    800021f0:	bfdd                	j	800021e6 <exit+0x4c>
  begin_op();
    800021f2:	00002097          	auipc	ra,0x2
    800021f6:	fde080e7          	jalr	-34(ra) # 800041d0 <begin_op>
  iput(p->cwd);
    800021fa:	1509b503          	ld	a0,336(s3)
    800021fe:	00001097          	auipc	ra,0x1
    80002202:	7c0080e7          	jalr	1984(ra) # 800039be <iput>
  end_op();
    80002206:	00002097          	auipc	ra,0x2
    8000220a:	048080e7          	jalr	72(ra) # 8000424e <end_op>
  p->cwd = 0;
    8000220e:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002212:	0000f497          	auipc	s1,0xf
    80002216:	a0648493          	addi	s1,s1,-1530 # 80010c18 <wait_lock>
    8000221a:	8526                	mv	a0,s1
    8000221c:	fffff097          	auipc	ra,0xfffff
    80002220:	9ba080e7          	jalr	-1606(ra) # 80000bd6 <acquire>
  reparent(p);
    80002224:	854e                	mv	a0,s3
    80002226:	00000097          	auipc	ra,0x0
    8000222a:	f1a080e7          	jalr	-230(ra) # 80002140 <reparent>
  wakeup(p->parent);
    8000222e:	0389b503          	ld	a0,56(s3)
    80002232:	00000097          	auipc	ra,0x0
    80002236:	e98080e7          	jalr	-360(ra) # 800020ca <wakeup>
  acquire(&p->lock);
    8000223a:	854e                	mv	a0,s3
    8000223c:	fffff097          	auipc	ra,0xfffff
    80002240:	99a080e7          	jalr	-1638(ra) # 80000bd6 <acquire>
  p->xstate = status;
    80002244:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002248:	4795                	li	a5,5
    8000224a:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000224e:	8526                	mv	a0,s1
    80002250:	fffff097          	auipc	ra,0xfffff
    80002254:	a3a080e7          	jalr	-1478(ra) # 80000c8a <release>
  sched();
    80002258:	00000097          	auipc	ra,0x0
    8000225c:	cfc080e7          	jalr	-772(ra) # 80001f54 <sched>
  panic("zombie exit");
    80002260:	00006517          	auipc	a0,0x6
    80002264:	01050513          	addi	a0,a0,16 # 80008270 <digits+0x230>
    80002268:	ffffe097          	auipc	ra,0xffffe
    8000226c:	2d8080e7          	jalr	728(ra) # 80000540 <panic>

0000000080002270 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002270:	7179                	addi	sp,sp,-48
    80002272:	f406                	sd	ra,40(sp)
    80002274:	f022                	sd	s0,32(sp)
    80002276:	ec26                	sd	s1,24(sp)
    80002278:	e84a                	sd	s2,16(sp)
    8000227a:	e44e                	sd	s3,8(sp)
    8000227c:	1800                	addi	s0,sp,48
    8000227e:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002280:	0000f497          	auipc	s1,0xf
    80002284:	db048493          	addi	s1,s1,-592 # 80011030 <proc>
    80002288:	00015997          	auipc	s3,0x15
    8000228c:	9a898993          	addi	s3,s3,-1624 # 80016c30 <tickslock>
    acquire(&p->lock);
    80002290:	8526                	mv	a0,s1
    80002292:	fffff097          	auipc	ra,0xfffff
    80002296:	944080e7          	jalr	-1724(ra) # 80000bd6 <acquire>
    if(p->pid == pid){
    8000229a:	589c                	lw	a5,48(s1)
    8000229c:	01278d63          	beq	a5,s2,800022b6 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800022a0:	8526                	mv	a0,s1
    800022a2:	fffff097          	auipc	ra,0xfffff
    800022a6:	9e8080e7          	jalr	-1560(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800022aa:	17048493          	addi	s1,s1,368
    800022ae:	ff3491e3          	bne	s1,s3,80002290 <kill+0x20>
  }
  return -1;
    800022b2:	557d                	li	a0,-1
    800022b4:	a829                	j	800022ce <kill+0x5e>
      p->killed = 1;
    800022b6:	4785                	li	a5,1
    800022b8:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800022ba:	4c98                	lw	a4,24(s1)
    800022bc:	4789                	li	a5,2
    800022be:	00f70f63          	beq	a4,a5,800022dc <kill+0x6c>
      release(&p->lock);
    800022c2:	8526                	mv	a0,s1
    800022c4:	fffff097          	auipc	ra,0xfffff
    800022c8:	9c6080e7          	jalr	-1594(ra) # 80000c8a <release>
      return 0;
    800022cc:	4501                	li	a0,0
}
    800022ce:	70a2                	ld	ra,40(sp)
    800022d0:	7402                	ld	s0,32(sp)
    800022d2:	64e2                	ld	s1,24(sp)
    800022d4:	6942                	ld	s2,16(sp)
    800022d6:	69a2                	ld	s3,8(sp)
    800022d8:	6145                	addi	sp,sp,48
    800022da:	8082                	ret
        p->state = RUNNABLE;
    800022dc:	478d                	li	a5,3
    800022de:	cc9c                	sw	a5,24(s1)
    800022e0:	b7cd                	j	800022c2 <kill+0x52>

00000000800022e2 <setkilled>:

void
setkilled(struct proc *p)
{
    800022e2:	1101                	addi	sp,sp,-32
    800022e4:	ec06                	sd	ra,24(sp)
    800022e6:	e822                	sd	s0,16(sp)
    800022e8:	e426                	sd	s1,8(sp)
    800022ea:	1000                	addi	s0,sp,32
    800022ec:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022ee:	fffff097          	auipc	ra,0xfffff
    800022f2:	8e8080e7          	jalr	-1816(ra) # 80000bd6 <acquire>
  p->killed = 1;
    800022f6:	4785                	li	a5,1
    800022f8:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800022fa:	8526                	mv	a0,s1
    800022fc:	fffff097          	auipc	ra,0xfffff
    80002300:	98e080e7          	jalr	-1650(ra) # 80000c8a <release>
}
    80002304:	60e2                	ld	ra,24(sp)
    80002306:	6442                	ld	s0,16(sp)
    80002308:	64a2                	ld	s1,8(sp)
    8000230a:	6105                	addi	sp,sp,32
    8000230c:	8082                	ret

000000008000230e <killed>:

int
killed(struct proc *p)
{
    8000230e:	1101                	addi	sp,sp,-32
    80002310:	ec06                	sd	ra,24(sp)
    80002312:	e822                	sd	s0,16(sp)
    80002314:	e426                	sd	s1,8(sp)
    80002316:	e04a                	sd	s2,0(sp)
    80002318:	1000                	addi	s0,sp,32
    8000231a:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    8000231c:	fffff097          	auipc	ra,0xfffff
    80002320:	8ba080e7          	jalr	-1862(ra) # 80000bd6 <acquire>
  k = p->killed;
    80002324:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002328:	8526                	mv	a0,s1
    8000232a:	fffff097          	auipc	ra,0xfffff
    8000232e:	960080e7          	jalr	-1696(ra) # 80000c8a <release>
  return k;
}
    80002332:	854a                	mv	a0,s2
    80002334:	60e2                	ld	ra,24(sp)
    80002336:	6442                	ld	s0,16(sp)
    80002338:	64a2                	ld	s1,8(sp)
    8000233a:	6902                	ld	s2,0(sp)
    8000233c:	6105                	addi	sp,sp,32
    8000233e:	8082                	ret

0000000080002340 <wait>:
{
    80002340:	715d                	addi	sp,sp,-80
    80002342:	e486                	sd	ra,72(sp)
    80002344:	e0a2                	sd	s0,64(sp)
    80002346:	fc26                	sd	s1,56(sp)
    80002348:	f84a                	sd	s2,48(sp)
    8000234a:	f44e                	sd	s3,40(sp)
    8000234c:	f052                	sd	s4,32(sp)
    8000234e:	ec56                	sd	s5,24(sp)
    80002350:	e85a                	sd	s6,16(sp)
    80002352:	e45e                	sd	s7,8(sp)
    80002354:	e062                	sd	s8,0(sp)
    80002356:	0880                	addi	s0,sp,80
    80002358:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000235a:	fffff097          	auipc	ra,0xfffff
    8000235e:	652080e7          	jalr	1618(ra) # 800019ac <myproc>
    80002362:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002364:	0000f517          	auipc	a0,0xf
    80002368:	8b450513          	addi	a0,a0,-1868 # 80010c18 <wait_lock>
    8000236c:	fffff097          	auipc	ra,0xfffff
    80002370:	86a080e7          	jalr	-1942(ra) # 80000bd6 <acquire>
    havekids = 0;
    80002374:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    80002376:	4a15                	li	s4,5
        havekids = 1;
    80002378:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000237a:	00015997          	auipc	s3,0x15
    8000237e:	8b698993          	addi	s3,s3,-1866 # 80016c30 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002382:	0000fc17          	auipc	s8,0xf
    80002386:	896c0c13          	addi	s8,s8,-1898 # 80010c18 <wait_lock>
    havekids = 0;
    8000238a:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000238c:	0000f497          	auipc	s1,0xf
    80002390:	ca448493          	addi	s1,s1,-860 # 80011030 <proc>
    80002394:	a0bd                	j	80002402 <wait+0xc2>
          pid = pp->pid;
    80002396:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    8000239a:	000b0e63          	beqz	s6,800023b6 <wait+0x76>
    8000239e:	4691                	li	a3,4
    800023a0:	02c48613          	addi	a2,s1,44
    800023a4:	85da                	mv	a1,s6
    800023a6:	05093503          	ld	a0,80(s2)
    800023aa:	fffff097          	auipc	ra,0xfffff
    800023ae:	2c2080e7          	jalr	706(ra) # 8000166c <copyout>
    800023b2:	02054563          	bltz	a0,800023dc <wait+0x9c>
          freeproc(pp);
    800023b6:	8526                	mv	a0,s1
    800023b8:	fffff097          	auipc	ra,0xfffff
    800023bc:	7a6080e7          	jalr	1958(ra) # 80001b5e <freeproc>
          release(&pp->lock);
    800023c0:	8526                	mv	a0,s1
    800023c2:	fffff097          	auipc	ra,0xfffff
    800023c6:	8c8080e7          	jalr	-1848(ra) # 80000c8a <release>
          release(&wait_lock);
    800023ca:	0000f517          	auipc	a0,0xf
    800023ce:	84e50513          	addi	a0,a0,-1970 # 80010c18 <wait_lock>
    800023d2:	fffff097          	auipc	ra,0xfffff
    800023d6:	8b8080e7          	jalr	-1864(ra) # 80000c8a <release>
          return pid;
    800023da:	a0b5                	j	80002446 <wait+0x106>
            release(&pp->lock);
    800023dc:	8526                	mv	a0,s1
    800023de:	fffff097          	auipc	ra,0xfffff
    800023e2:	8ac080e7          	jalr	-1876(ra) # 80000c8a <release>
            release(&wait_lock);
    800023e6:	0000f517          	auipc	a0,0xf
    800023ea:	83250513          	addi	a0,a0,-1998 # 80010c18 <wait_lock>
    800023ee:	fffff097          	auipc	ra,0xfffff
    800023f2:	89c080e7          	jalr	-1892(ra) # 80000c8a <release>
            return -1;
    800023f6:	59fd                	li	s3,-1
    800023f8:	a0b9                	j	80002446 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023fa:	17048493          	addi	s1,s1,368
    800023fe:	03348463          	beq	s1,s3,80002426 <wait+0xe6>
      if(pp->parent == p){
    80002402:	7c9c                	ld	a5,56(s1)
    80002404:	ff279be3          	bne	a5,s2,800023fa <wait+0xba>
        acquire(&pp->lock);
    80002408:	8526                	mv	a0,s1
    8000240a:	ffffe097          	auipc	ra,0xffffe
    8000240e:	7cc080e7          	jalr	1996(ra) # 80000bd6 <acquire>
        if(pp->state == ZOMBIE){
    80002412:	4c9c                	lw	a5,24(s1)
    80002414:	f94781e3          	beq	a5,s4,80002396 <wait+0x56>
        release(&pp->lock);
    80002418:	8526                	mv	a0,s1
    8000241a:	fffff097          	auipc	ra,0xfffff
    8000241e:	870080e7          	jalr	-1936(ra) # 80000c8a <release>
        havekids = 1;
    80002422:	8756                	mv	a4,s5
    80002424:	bfd9                	j	800023fa <wait+0xba>
    if(!havekids || killed(p)){
    80002426:	c719                	beqz	a4,80002434 <wait+0xf4>
    80002428:	854a                	mv	a0,s2
    8000242a:	00000097          	auipc	ra,0x0
    8000242e:	ee4080e7          	jalr	-284(ra) # 8000230e <killed>
    80002432:	c51d                	beqz	a0,80002460 <wait+0x120>
      release(&wait_lock);
    80002434:	0000e517          	auipc	a0,0xe
    80002438:	7e450513          	addi	a0,a0,2020 # 80010c18 <wait_lock>
    8000243c:	fffff097          	auipc	ra,0xfffff
    80002440:	84e080e7          	jalr	-1970(ra) # 80000c8a <release>
      return -1;
    80002444:	59fd                	li	s3,-1
}
    80002446:	854e                	mv	a0,s3
    80002448:	60a6                	ld	ra,72(sp)
    8000244a:	6406                	ld	s0,64(sp)
    8000244c:	74e2                	ld	s1,56(sp)
    8000244e:	7942                	ld	s2,48(sp)
    80002450:	79a2                	ld	s3,40(sp)
    80002452:	7a02                	ld	s4,32(sp)
    80002454:	6ae2                	ld	s5,24(sp)
    80002456:	6b42                	ld	s6,16(sp)
    80002458:	6ba2                	ld	s7,8(sp)
    8000245a:	6c02                	ld	s8,0(sp)
    8000245c:	6161                	addi	sp,sp,80
    8000245e:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002460:	85e2                	mv	a1,s8
    80002462:	854a                	mv	a0,s2
    80002464:	00000097          	auipc	ra,0x0
    80002468:	c02080e7          	jalr	-1022(ra) # 80002066 <sleep>
    havekids = 0;
    8000246c:	bf39                	j	8000238a <wait+0x4a>

000000008000246e <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000246e:	7179                	addi	sp,sp,-48
    80002470:	f406                	sd	ra,40(sp)
    80002472:	f022                	sd	s0,32(sp)
    80002474:	ec26                	sd	s1,24(sp)
    80002476:	e84a                	sd	s2,16(sp)
    80002478:	e44e                	sd	s3,8(sp)
    8000247a:	e052                	sd	s4,0(sp)
    8000247c:	1800                	addi	s0,sp,48
    8000247e:	84aa                	mv	s1,a0
    80002480:	892e                	mv	s2,a1
    80002482:	89b2                	mv	s3,a2
    80002484:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002486:	fffff097          	auipc	ra,0xfffff
    8000248a:	526080e7          	jalr	1318(ra) # 800019ac <myproc>
  if(user_dst){
    8000248e:	c08d                	beqz	s1,800024b0 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002490:	86d2                	mv	a3,s4
    80002492:	864e                	mv	a2,s3
    80002494:	85ca                	mv	a1,s2
    80002496:	6928                	ld	a0,80(a0)
    80002498:	fffff097          	auipc	ra,0xfffff
    8000249c:	1d4080e7          	jalr	468(ra) # 8000166c <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024a0:	70a2                	ld	ra,40(sp)
    800024a2:	7402                	ld	s0,32(sp)
    800024a4:	64e2                	ld	s1,24(sp)
    800024a6:	6942                	ld	s2,16(sp)
    800024a8:	69a2                	ld	s3,8(sp)
    800024aa:	6a02                	ld	s4,0(sp)
    800024ac:	6145                	addi	sp,sp,48
    800024ae:	8082                	ret
    memmove((char *)dst, src, len);
    800024b0:	000a061b          	sext.w	a2,s4
    800024b4:	85ce                	mv	a1,s3
    800024b6:	854a                	mv	a0,s2
    800024b8:	fffff097          	auipc	ra,0xfffff
    800024bc:	876080e7          	jalr	-1930(ra) # 80000d2e <memmove>
    return 0;
    800024c0:	8526                	mv	a0,s1
    800024c2:	bff9                	j	800024a0 <either_copyout+0x32>

00000000800024c4 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024c4:	7179                	addi	sp,sp,-48
    800024c6:	f406                	sd	ra,40(sp)
    800024c8:	f022                	sd	s0,32(sp)
    800024ca:	ec26                	sd	s1,24(sp)
    800024cc:	e84a                	sd	s2,16(sp)
    800024ce:	e44e                	sd	s3,8(sp)
    800024d0:	e052                	sd	s4,0(sp)
    800024d2:	1800                	addi	s0,sp,48
    800024d4:	892a                	mv	s2,a0
    800024d6:	84ae                	mv	s1,a1
    800024d8:	89b2                	mv	s3,a2
    800024da:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024dc:	fffff097          	auipc	ra,0xfffff
    800024e0:	4d0080e7          	jalr	1232(ra) # 800019ac <myproc>
  if(user_src){
    800024e4:	c08d                	beqz	s1,80002506 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024e6:	86d2                	mv	a3,s4
    800024e8:	864e                	mv	a2,s3
    800024ea:	85ca                	mv	a1,s2
    800024ec:	6928                	ld	a0,80(a0)
    800024ee:	fffff097          	auipc	ra,0xfffff
    800024f2:	20a080e7          	jalr	522(ra) # 800016f8 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024f6:	70a2                	ld	ra,40(sp)
    800024f8:	7402                	ld	s0,32(sp)
    800024fa:	64e2                	ld	s1,24(sp)
    800024fc:	6942                	ld	s2,16(sp)
    800024fe:	69a2                	ld	s3,8(sp)
    80002500:	6a02                	ld	s4,0(sp)
    80002502:	6145                	addi	sp,sp,48
    80002504:	8082                	ret
    memmove(dst, (char*)src, len);
    80002506:	000a061b          	sext.w	a2,s4
    8000250a:	85ce                	mv	a1,s3
    8000250c:	854a                	mv	a0,s2
    8000250e:	fffff097          	auipc	ra,0xfffff
    80002512:	820080e7          	jalr	-2016(ra) # 80000d2e <memmove>
    return 0;
    80002516:	8526                	mv	a0,s1
    80002518:	bff9                	j	800024f6 <either_copyin+0x32>

000000008000251a <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000251a:	715d                	addi	sp,sp,-80
    8000251c:	e486                	sd	ra,72(sp)
    8000251e:	e0a2                	sd	s0,64(sp)
    80002520:	fc26                	sd	s1,56(sp)
    80002522:	f84a                	sd	s2,48(sp)
    80002524:	f44e                	sd	s3,40(sp)
    80002526:	f052                	sd	s4,32(sp)
    80002528:	ec56                	sd	s5,24(sp)
    8000252a:	e85a                	sd	s6,16(sp)
    8000252c:	e45e                	sd	s7,8(sp)
    8000252e:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002530:	00006517          	auipc	a0,0x6
    80002534:	b9850513          	addi	a0,a0,-1128 # 800080c8 <digits+0x88>
    80002538:	ffffe097          	auipc	ra,0xffffe
    8000253c:	052080e7          	jalr	82(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002540:	0000f497          	auipc	s1,0xf
    80002544:	c4848493          	addi	s1,s1,-952 # 80011188 <proc+0x158>
    80002548:	00015917          	auipc	s2,0x15
    8000254c:	84090913          	addi	s2,s2,-1984 # 80016d88 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002550:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002552:	00006997          	auipc	s3,0x6
    80002556:	d2e98993          	addi	s3,s3,-722 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    8000255a:	00006a97          	auipc	s5,0x6
    8000255e:	d2ea8a93          	addi	s5,s5,-722 # 80008288 <digits+0x248>
    printf("\n");
    80002562:	00006a17          	auipc	s4,0x6
    80002566:	b66a0a13          	addi	s4,s4,-1178 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000256a:	00006b97          	auipc	s7,0x6
    8000256e:	df6b8b93          	addi	s7,s7,-522 # 80008360 <states.0>
    80002572:	a00d                	j	80002594 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002574:	ed86a583          	lw	a1,-296(a3)
    80002578:	8556                	mv	a0,s5
    8000257a:	ffffe097          	auipc	ra,0xffffe
    8000257e:	010080e7          	jalr	16(ra) # 8000058a <printf>
    printf("\n");
    80002582:	8552                	mv	a0,s4
    80002584:	ffffe097          	auipc	ra,0xffffe
    80002588:	006080e7          	jalr	6(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000258c:	17048493          	addi	s1,s1,368
    80002590:	03248263          	beq	s1,s2,800025b4 <procdump+0x9a>
    if(p->state == UNUSED)
    80002594:	86a6                	mv	a3,s1
    80002596:	ec04a783          	lw	a5,-320(s1)
    8000259a:	dbed                	beqz	a5,8000258c <procdump+0x72>
      state = "???";
    8000259c:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000259e:	fcfb6be3          	bltu	s6,a5,80002574 <procdump+0x5a>
    800025a2:	02079713          	slli	a4,a5,0x20
    800025a6:	01d75793          	srli	a5,a4,0x1d
    800025aa:	97de                	add	a5,a5,s7
    800025ac:	6390                	ld	a2,0(a5)
    800025ae:	f279                	bnez	a2,80002574 <procdump+0x5a>
      state = "???";
    800025b0:	864e                	mv	a2,s3
    800025b2:	b7c9                	j	80002574 <procdump+0x5a>
  }
}
    800025b4:	60a6                	ld	ra,72(sp)
    800025b6:	6406                	ld	s0,64(sp)
    800025b8:	74e2                	ld	s1,56(sp)
    800025ba:	7942                	ld	s2,48(sp)
    800025bc:	79a2                	ld	s3,40(sp)
    800025be:	7a02                	ld	s4,32(sp)
    800025c0:	6ae2                	ld	s5,24(sp)
    800025c2:	6b42                	ld	s6,16(sp)
    800025c4:	6ba2                	ld	s7,8(sp)
    800025c6:	6161                	addi	sp,sp,80
    800025c8:	8082                	ret

00000000800025ca <chprio>:
int chprio(int pid, int priority)
{
    800025ca:	715d                	addi	sp,sp,-80
    800025cc:	e486                	sd	ra,72(sp)
    800025ce:	e0a2                	sd	s0,64(sp)
    800025d0:	fc26                	sd	s1,56(sp)
    800025d2:	f84a                	sd	s2,48(sp)
    800025d4:	f44e                	sd	s3,40(sp)
    800025d6:	0880                	addi	s0,sp,80
    800025d8:	892a                	mv	s2,a0
    800025da:	89ae                	mv	s3,a1
	
	struct proc *p;
	for(p = proc; p < &proc[NPROC]; p++){
    800025dc:	0000f497          	auipc	s1,0xf
    800025e0:	a5448493          	addi	s1,s1,-1452 # 80011030 <proc>
    800025e4:	00014717          	auipc	a4,0x14
    800025e8:	64c70713          	addi	a4,a4,1612 # 80016c30 <tickslock>
   
	  if(p->pid == pid){
    800025ec:	589c                	lw	a5,48(s1)
    800025ee:	01278763          	beq	a5,s2,800025fc <chprio+0x32>
	for(p = proc; p < &proc[NPROC]; p++){
    800025f2:	17048493          	addi	s1,s1,368
    800025f6:	fee49be3          	bne	s1,a4,800025ec <chprio+0x22>
    800025fa:	a81d                	j	80002630 <chprio+0x66>
      printf("%s \t %d \t %d \n %d ", p->name,p->pid,p->priority,p->lock);
    800025fc:	609c                	ld	a5,0(s1)
    800025fe:	faf43823          	sd	a5,-80(s0)
    80002602:	649c                	ld	a5,8(s1)
    80002604:	faf43c23          	sd	a5,-72(s0)
    80002608:	689c                	ld	a5,16(s1)
    8000260a:	fcf43023          	sd	a5,-64(s0)
    8000260e:	fb040713          	addi	a4,s0,-80
    80002612:	1684a683          	lw	a3,360(s1)
    80002616:	864a                	mv	a2,s2
    80002618:	15848593          	addi	a1,s1,344
    8000261c:	00006517          	auipc	a0,0x6
    80002620:	c7c50513          	addi	a0,a0,-900 # 80008298 <digits+0x258>
    80002624:	ffffe097          	auipc	ra,0xffffe
    80002628:	f66080e7          	jalr	-154(ra) # 8000058a <printf>
			p->priority = priority;
    8000262c:	1734a423          	sw	s3,360(s1)
		}
   
	}
	
	return pid;
}
    80002630:	854a                	mv	a0,s2
    80002632:	60a6                	ld	ra,72(sp)
    80002634:	6406                	ld	s0,64(sp)
    80002636:	74e2                	ld	s1,56(sp)
    80002638:	7942                	ld	s2,48(sp)
    8000263a:	79a2                	ld	s3,40(sp)
    8000263c:	6161                	addi	sp,sp,80
    8000263e:	8082                	ret

0000000080002640 <procs>:

int procs(void)
{
    80002640:	711d                	addi	sp,sp,-96
    80002642:	ec86                	sd	ra,88(sp)
    80002644:	e8a2                	sd	s0,80(sp)
    80002646:	e4a6                	sd	s1,72(sp)
    80002648:	e0ca                	sd	s2,64(sp)
    8000264a:	fc4e                	sd	s3,56(sp)
    8000264c:	f852                	sd	s4,48(sp)
    8000264e:	f456                	sd	s5,40(sp)
    80002650:	f05a                	sd	s6,32(sp)
    80002652:	ec5e                	sd	s7,24(sp)
    80002654:	e862                	sd	s8,16(sp)
    80002656:	e466                	sd	s9,8(sp)
    80002658:	1080                	addi	s0,sp,96
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000265a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000265e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002662:	10079073          	csrw	sstatus,a5
  struct proc *p;
  intr_on();
  
  printf("name \t pid \t state \t priority \n");
    80002666:	00006517          	auipc	a0,0x6
    8000266a:	c4a50513          	addi	a0,a0,-950 # 800082b0 <digits+0x270>
    8000266e:	ffffe097          	auipc	ra,0xffffe
    80002672:	f1c080e7          	jalr	-228(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002676:	0000f497          	auipc	s1,0xf
    8000267a:	b1248493          	addi	s1,s1,-1262 # 80011188 <proc+0x158>
    8000267e:	00014a17          	auipc	s4,0x14
    80002682:	70aa0a13          	addi	s4,s4,1802 # 80016d88 <bcache+0x140>
    struct proc *pp = myproc();
     acquire(&pp->lock);
    if(p->state == SLEEPING)
    80002686:	4989                	li	s3,2
      printf("%s \t %d \t SLEEPING \t %d \n ", p->name,p->pid,p->priority);
    else if(p->state == RUNNING)
    80002688:	4a91                	li	s5,4
      printf("%s \t %d \t RUNNING \t %d \n ", p->name,p->pid,p->priority);
    else if(p->state == RUNNABLE)
    8000268a:	4b0d                	li	s6,3
      printf("%s \t %d \t RUNNABLE \t %d \n ", p->name,p->pid,p->priority);
    8000268c:	00006c97          	auipc	s9,0x6
    80002690:	c84c8c93          	addi	s9,s9,-892 # 80008310 <digits+0x2d0>
      printf("%s \t %d \t RUNNING \t %d \n ", p->name,p->pid,p->priority);
    80002694:	00006c17          	auipc	s8,0x6
    80002698:	c5cc0c13          	addi	s8,s8,-932 # 800082f0 <digits+0x2b0>
      printf("%s \t %d \t SLEEPING \t %d \n ", p->name,p->pid,p->priority);
    8000269c:	00006b97          	auipc	s7,0x6
    800026a0:	c34b8b93          	addi	s7,s7,-972 # 800082d0 <digits+0x290>
    800026a4:	a015                	j	800026c8 <procs+0x88>
    800026a6:	4894                	lw	a3,16(s1)
    800026a8:	ed84a603          	lw	a2,-296(s1)
    800026ac:	855e                	mv	a0,s7
    800026ae:	ffffe097          	auipc	ra,0xffffe
    800026b2:	edc080e7          	jalr	-292(ra) # 8000058a <printf>
    release(&pp->lock);
    800026b6:	854a                	mv	a0,s2
    800026b8:	ffffe097          	auipc	ra,0xffffe
    800026bc:	5d2080e7          	jalr	1490(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800026c0:	17048493          	addi	s1,s1,368
    800026c4:	05448663          	beq	s1,s4,80002710 <procs+0xd0>
    struct proc *pp = myproc();
    800026c8:	fffff097          	auipc	ra,0xfffff
    800026cc:	2e4080e7          	jalr	740(ra) # 800019ac <myproc>
    800026d0:	892a                	mv	s2,a0
     acquire(&pp->lock);
    800026d2:	ffffe097          	auipc	ra,0xffffe
    800026d6:	504080e7          	jalr	1284(ra) # 80000bd6 <acquire>
    if(p->state == SLEEPING)
    800026da:	85a6                	mv	a1,s1
    800026dc:	ec04a783          	lw	a5,-320(s1)
    800026e0:	fd3783e3          	beq	a5,s3,800026a6 <procs+0x66>
    else if(p->state == RUNNING)
    800026e4:	01578d63          	beq	a5,s5,800026fe <procs+0xbe>
    else if(p->state == RUNNABLE)
    800026e8:	fd6797e3          	bne	a5,s6,800026b6 <procs+0x76>
      printf("%s \t %d \t RUNNABLE \t %d \n ", p->name,p->pid,p->priority);
    800026ec:	4894                	lw	a3,16(s1)
    800026ee:	ed84a603          	lw	a2,-296(s1)
    800026f2:	8566                	mv	a0,s9
    800026f4:	ffffe097          	auipc	ra,0xffffe
    800026f8:	e96080e7          	jalr	-362(ra) # 8000058a <printf>
    800026fc:	bf6d                	j	800026b6 <procs+0x76>
      printf("%s \t %d \t RUNNING \t %d \n ", p->name,p->pid,p->priority);
    800026fe:	4894                	lw	a3,16(s1)
    80002700:	ed84a603          	lw	a2,-296(s1)
    80002704:	8562                	mv	a0,s8
    80002706:	ffffe097          	auipc	ra,0xffffe
    8000270a:	e84080e7          	jalr	-380(ra) # 8000058a <printf>
    8000270e:	b765                	j	800026b6 <procs+0x76>
    
}

  return 23;
}
    80002710:	455d                	li	a0,23
    80002712:	60e6                	ld	ra,88(sp)
    80002714:	6446                	ld	s0,80(sp)
    80002716:	64a6                	ld	s1,72(sp)
    80002718:	6906                	ld	s2,64(sp)
    8000271a:	79e2                	ld	s3,56(sp)
    8000271c:	7a42                	ld	s4,48(sp)
    8000271e:	7aa2                	ld	s5,40(sp)
    80002720:	7b02                	ld	s6,32(sp)
    80002722:	6be2                	ld	s7,24(sp)
    80002724:	6c42                	ld	s8,16(sp)
    80002726:	6ca2                	ld	s9,8(sp)
    80002728:	6125                	addi	sp,sp,96
    8000272a:	8082                	ret

000000008000272c <swtch>:
    8000272c:	00153023          	sd	ra,0(a0)
    80002730:	00253423          	sd	sp,8(a0)
    80002734:	e900                	sd	s0,16(a0)
    80002736:	ed04                	sd	s1,24(a0)
    80002738:	03253023          	sd	s2,32(a0)
    8000273c:	03353423          	sd	s3,40(a0)
    80002740:	03453823          	sd	s4,48(a0)
    80002744:	03553c23          	sd	s5,56(a0)
    80002748:	05653023          	sd	s6,64(a0)
    8000274c:	05753423          	sd	s7,72(a0)
    80002750:	05853823          	sd	s8,80(a0)
    80002754:	05953c23          	sd	s9,88(a0)
    80002758:	07a53023          	sd	s10,96(a0)
    8000275c:	07b53423          	sd	s11,104(a0)
    80002760:	0005b083          	ld	ra,0(a1)
    80002764:	0085b103          	ld	sp,8(a1)
    80002768:	6980                	ld	s0,16(a1)
    8000276a:	6d84                	ld	s1,24(a1)
    8000276c:	0205b903          	ld	s2,32(a1)
    80002770:	0285b983          	ld	s3,40(a1)
    80002774:	0305ba03          	ld	s4,48(a1)
    80002778:	0385ba83          	ld	s5,56(a1)
    8000277c:	0405bb03          	ld	s6,64(a1)
    80002780:	0485bb83          	ld	s7,72(a1)
    80002784:	0505bc03          	ld	s8,80(a1)
    80002788:	0585bc83          	ld	s9,88(a1)
    8000278c:	0605bd03          	ld	s10,96(a1)
    80002790:	0685bd83          	ld	s11,104(a1)
    80002794:	8082                	ret

0000000080002796 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002796:	1141                	addi	sp,sp,-16
    80002798:	e406                	sd	ra,8(sp)
    8000279a:	e022                	sd	s0,0(sp)
    8000279c:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000279e:	00006597          	auipc	a1,0x6
    800027a2:	bf258593          	addi	a1,a1,-1038 # 80008390 <states.0+0x30>
    800027a6:	00014517          	auipc	a0,0x14
    800027aa:	48a50513          	addi	a0,a0,1162 # 80016c30 <tickslock>
    800027ae:	ffffe097          	auipc	ra,0xffffe
    800027b2:	398080e7          	jalr	920(ra) # 80000b46 <initlock>
}
    800027b6:	60a2                	ld	ra,8(sp)
    800027b8:	6402                	ld	s0,0(sp)
    800027ba:	0141                	addi	sp,sp,16
    800027bc:	8082                	ret

00000000800027be <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800027be:	1141                	addi	sp,sp,-16
    800027c0:	e422                	sd	s0,8(sp)
    800027c2:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027c4:	00003797          	auipc	a5,0x3
    800027c8:	52c78793          	addi	a5,a5,1324 # 80005cf0 <kernelvec>
    800027cc:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800027d0:	6422                	ld	s0,8(sp)
    800027d2:	0141                	addi	sp,sp,16
    800027d4:	8082                	ret

00000000800027d6 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800027d6:	1141                	addi	sp,sp,-16
    800027d8:	e406                	sd	ra,8(sp)
    800027da:	e022                	sd	s0,0(sp)
    800027dc:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800027de:	fffff097          	auipc	ra,0xfffff
    800027e2:	1ce080e7          	jalr	462(ra) # 800019ac <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027e6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800027ea:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027ec:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800027f0:	00005697          	auipc	a3,0x5
    800027f4:	81068693          	addi	a3,a3,-2032 # 80007000 <_trampoline>
    800027f8:	00005717          	auipc	a4,0x5
    800027fc:	80870713          	addi	a4,a4,-2040 # 80007000 <_trampoline>
    80002800:	8f15                	sub	a4,a4,a3
    80002802:	040007b7          	lui	a5,0x4000
    80002806:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002808:	07b2                	slli	a5,a5,0xc
    8000280a:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000280c:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002810:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002812:	18002673          	csrr	a2,satp
    80002816:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002818:	6d30                	ld	a2,88(a0)
    8000281a:	6138                	ld	a4,64(a0)
    8000281c:	6585                	lui	a1,0x1
    8000281e:	972e                	add	a4,a4,a1
    80002820:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002822:	6d38                	ld	a4,88(a0)
    80002824:	00000617          	auipc	a2,0x0
    80002828:	13060613          	addi	a2,a2,304 # 80002954 <usertrap>
    8000282c:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000282e:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002830:	8612                	mv	a2,tp
    80002832:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002834:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002838:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000283c:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002840:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002844:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002846:	6f18                	ld	a4,24(a4)
    80002848:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000284c:	6928                	ld	a0,80(a0)
    8000284e:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002850:	00005717          	auipc	a4,0x5
    80002854:	84c70713          	addi	a4,a4,-1972 # 8000709c <userret>
    80002858:	8f15                	sub	a4,a4,a3
    8000285a:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    8000285c:	577d                	li	a4,-1
    8000285e:	177e                	slli	a4,a4,0x3f
    80002860:	8d59                	or	a0,a0,a4
    80002862:	9782                	jalr	a5
}
    80002864:	60a2                	ld	ra,8(sp)
    80002866:	6402                	ld	s0,0(sp)
    80002868:	0141                	addi	sp,sp,16
    8000286a:	8082                	ret

000000008000286c <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000286c:	1101                	addi	sp,sp,-32
    8000286e:	ec06                	sd	ra,24(sp)
    80002870:	e822                	sd	s0,16(sp)
    80002872:	e426                	sd	s1,8(sp)
    80002874:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002876:	00014497          	auipc	s1,0x14
    8000287a:	3ba48493          	addi	s1,s1,954 # 80016c30 <tickslock>
    8000287e:	8526                	mv	a0,s1
    80002880:	ffffe097          	auipc	ra,0xffffe
    80002884:	356080e7          	jalr	854(ra) # 80000bd6 <acquire>
  ticks++;
    80002888:	00006517          	auipc	a0,0x6
    8000288c:	10850513          	addi	a0,a0,264 # 80008990 <ticks>
    80002890:	411c                	lw	a5,0(a0)
    80002892:	2785                	addiw	a5,a5,1
    80002894:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002896:	00000097          	auipc	ra,0x0
    8000289a:	834080e7          	jalr	-1996(ra) # 800020ca <wakeup>
  release(&tickslock);
    8000289e:	8526                	mv	a0,s1
    800028a0:	ffffe097          	auipc	ra,0xffffe
    800028a4:	3ea080e7          	jalr	1002(ra) # 80000c8a <release>
}
    800028a8:	60e2                	ld	ra,24(sp)
    800028aa:	6442                	ld	s0,16(sp)
    800028ac:	64a2                	ld	s1,8(sp)
    800028ae:	6105                	addi	sp,sp,32
    800028b0:	8082                	ret

00000000800028b2 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800028b2:	1101                	addi	sp,sp,-32
    800028b4:	ec06                	sd	ra,24(sp)
    800028b6:	e822                	sd	s0,16(sp)
    800028b8:	e426                	sd	s1,8(sp)
    800028ba:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028bc:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800028c0:	00074d63          	bltz	a4,800028da <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800028c4:	57fd                	li	a5,-1
    800028c6:	17fe                	slli	a5,a5,0x3f
    800028c8:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800028ca:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800028cc:	06f70363          	beq	a4,a5,80002932 <devintr+0x80>
  }
}
    800028d0:	60e2                	ld	ra,24(sp)
    800028d2:	6442                	ld	s0,16(sp)
    800028d4:	64a2                	ld	s1,8(sp)
    800028d6:	6105                	addi	sp,sp,32
    800028d8:	8082                	ret
     (scause & 0xff) == 9){
    800028da:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    800028de:	46a5                	li	a3,9
    800028e0:	fed792e3          	bne	a5,a3,800028c4 <devintr+0x12>
    int irq = plic_claim();
    800028e4:	00003097          	auipc	ra,0x3
    800028e8:	514080e7          	jalr	1300(ra) # 80005df8 <plic_claim>
    800028ec:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800028ee:	47a9                	li	a5,10
    800028f0:	02f50763          	beq	a0,a5,8000291e <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800028f4:	4785                	li	a5,1
    800028f6:	02f50963          	beq	a0,a5,80002928 <devintr+0x76>
    return 1;
    800028fa:	4505                	li	a0,1
    } else if(irq){
    800028fc:	d8f1                	beqz	s1,800028d0 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800028fe:	85a6                	mv	a1,s1
    80002900:	00006517          	auipc	a0,0x6
    80002904:	a9850513          	addi	a0,a0,-1384 # 80008398 <states.0+0x38>
    80002908:	ffffe097          	auipc	ra,0xffffe
    8000290c:	c82080e7          	jalr	-894(ra) # 8000058a <printf>
      plic_complete(irq);
    80002910:	8526                	mv	a0,s1
    80002912:	00003097          	auipc	ra,0x3
    80002916:	50a080e7          	jalr	1290(ra) # 80005e1c <plic_complete>
    return 1;
    8000291a:	4505                	li	a0,1
    8000291c:	bf55                	j	800028d0 <devintr+0x1e>
      uartintr();
    8000291e:	ffffe097          	auipc	ra,0xffffe
    80002922:	07a080e7          	jalr	122(ra) # 80000998 <uartintr>
    80002926:	b7ed                	j	80002910 <devintr+0x5e>
      virtio_disk_intr();
    80002928:	00004097          	auipc	ra,0x4
    8000292c:	9bc080e7          	jalr	-1604(ra) # 800062e4 <virtio_disk_intr>
    80002930:	b7c5                	j	80002910 <devintr+0x5e>
    if(cpuid() == 0){
    80002932:	fffff097          	auipc	ra,0xfffff
    80002936:	04e080e7          	jalr	78(ra) # 80001980 <cpuid>
    8000293a:	c901                	beqz	a0,8000294a <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000293c:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002940:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002942:	14479073          	csrw	sip,a5
    return 2;
    80002946:	4509                	li	a0,2
    80002948:	b761                	j	800028d0 <devintr+0x1e>
      clockintr();
    8000294a:	00000097          	auipc	ra,0x0
    8000294e:	f22080e7          	jalr	-222(ra) # 8000286c <clockintr>
    80002952:	b7ed                	j	8000293c <devintr+0x8a>

0000000080002954 <usertrap>:
{
    80002954:	1101                	addi	sp,sp,-32
    80002956:	ec06                	sd	ra,24(sp)
    80002958:	e822                	sd	s0,16(sp)
    8000295a:	e426                	sd	s1,8(sp)
    8000295c:	e04a                	sd	s2,0(sp)
    8000295e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002960:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002964:	1007f793          	andi	a5,a5,256
    80002968:	e3b1                	bnez	a5,800029ac <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000296a:	00003797          	auipc	a5,0x3
    8000296e:	38678793          	addi	a5,a5,902 # 80005cf0 <kernelvec>
    80002972:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002976:	fffff097          	auipc	ra,0xfffff
    8000297a:	036080e7          	jalr	54(ra) # 800019ac <myproc>
    8000297e:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002980:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002982:	14102773          	csrr	a4,sepc
    80002986:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002988:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000298c:	47a1                	li	a5,8
    8000298e:	02f70763          	beq	a4,a5,800029bc <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002992:	00000097          	auipc	ra,0x0
    80002996:	f20080e7          	jalr	-224(ra) # 800028b2 <devintr>
    8000299a:	892a                	mv	s2,a0
    8000299c:	c151                	beqz	a0,80002a20 <usertrap+0xcc>
  if(killed(p))
    8000299e:	8526                	mv	a0,s1
    800029a0:	00000097          	auipc	ra,0x0
    800029a4:	96e080e7          	jalr	-1682(ra) # 8000230e <killed>
    800029a8:	c929                	beqz	a0,800029fa <usertrap+0xa6>
    800029aa:	a099                	j	800029f0 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    800029ac:	00006517          	auipc	a0,0x6
    800029b0:	a0c50513          	addi	a0,a0,-1524 # 800083b8 <states.0+0x58>
    800029b4:	ffffe097          	auipc	ra,0xffffe
    800029b8:	b8c080e7          	jalr	-1140(ra) # 80000540 <panic>
    if(killed(p))
    800029bc:	00000097          	auipc	ra,0x0
    800029c0:	952080e7          	jalr	-1710(ra) # 8000230e <killed>
    800029c4:	e921                	bnez	a0,80002a14 <usertrap+0xc0>
    p->trapframe->epc += 4;
    800029c6:	6cb8                	ld	a4,88(s1)
    800029c8:	6f1c                	ld	a5,24(a4)
    800029ca:	0791                	addi	a5,a5,4
    800029cc:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029ce:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800029d2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029d6:	10079073          	csrw	sstatus,a5
    syscall();
    800029da:	00000097          	auipc	ra,0x0
    800029de:	2d4080e7          	jalr	724(ra) # 80002cae <syscall>
  if(killed(p))
    800029e2:	8526                	mv	a0,s1
    800029e4:	00000097          	auipc	ra,0x0
    800029e8:	92a080e7          	jalr	-1750(ra) # 8000230e <killed>
    800029ec:	c911                	beqz	a0,80002a00 <usertrap+0xac>
    800029ee:	4901                	li	s2,0
    exit(-1);
    800029f0:	557d                	li	a0,-1
    800029f2:	fffff097          	auipc	ra,0xfffff
    800029f6:	7a8080e7          	jalr	1960(ra) # 8000219a <exit>
  if(which_dev == 2)
    800029fa:	4789                	li	a5,2
    800029fc:	04f90f63          	beq	s2,a5,80002a5a <usertrap+0x106>
  usertrapret();
    80002a00:	00000097          	auipc	ra,0x0
    80002a04:	dd6080e7          	jalr	-554(ra) # 800027d6 <usertrapret>
}
    80002a08:	60e2                	ld	ra,24(sp)
    80002a0a:	6442                	ld	s0,16(sp)
    80002a0c:	64a2                	ld	s1,8(sp)
    80002a0e:	6902                	ld	s2,0(sp)
    80002a10:	6105                	addi	sp,sp,32
    80002a12:	8082                	ret
      exit(-1);
    80002a14:	557d                	li	a0,-1
    80002a16:	fffff097          	auipc	ra,0xfffff
    80002a1a:	784080e7          	jalr	1924(ra) # 8000219a <exit>
    80002a1e:	b765                	j	800029c6 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a20:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a24:	5890                	lw	a2,48(s1)
    80002a26:	00006517          	auipc	a0,0x6
    80002a2a:	9b250513          	addi	a0,a0,-1614 # 800083d8 <states.0+0x78>
    80002a2e:	ffffe097          	auipc	ra,0xffffe
    80002a32:	b5c080e7          	jalr	-1188(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a36:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a3a:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a3e:	00006517          	auipc	a0,0x6
    80002a42:	9ca50513          	addi	a0,a0,-1590 # 80008408 <states.0+0xa8>
    80002a46:	ffffe097          	auipc	ra,0xffffe
    80002a4a:	b44080e7          	jalr	-1212(ra) # 8000058a <printf>
    setkilled(p);
    80002a4e:	8526                	mv	a0,s1
    80002a50:	00000097          	auipc	ra,0x0
    80002a54:	892080e7          	jalr	-1902(ra) # 800022e2 <setkilled>
    80002a58:	b769                	j	800029e2 <usertrap+0x8e>
    yield();
    80002a5a:	fffff097          	auipc	ra,0xfffff
    80002a5e:	5d0080e7          	jalr	1488(ra) # 8000202a <yield>
    80002a62:	bf79                	j	80002a00 <usertrap+0xac>

0000000080002a64 <kerneltrap>:
{
    80002a64:	7179                	addi	sp,sp,-48
    80002a66:	f406                	sd	ra,40(sp)
    80002a68:	f022                	sd	s0,32(sp)
    80002a6a:	ec26                	sd	s1,24(sp)
    80002a6c:	e84a                	sd	s2,16(sp)
    80002a6e:	e44e                	sd	s3,8(sp)
    80002a70:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a72:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a76:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a7a:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a7e:	1004f793          	andi	a5,s1,256
    80002a82:	cb85                	beqz	a5,80002ab2 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a84:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a88:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a8a:	ef85                	bnez	a5,80002ac2 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a8c:	00000097          	auipc	ra,0x0
    80002a90:	e26080e7          	jalr	-474(ra) # 800028b2 <devintr>
    80002a94:	cd1d                	beqz	a0,80002ad2 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a96:	4789                	li	a5,2
    80002a98:	06f50a63          	beq	a0,a5,80002b0c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a9c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002aa0:	10049073          	csrw	sstatus,s1
}
    80002aa4:	70a2                	ld	ra,40(sp)
    80002aa6:	7402                	ld	s0,32(sp)
    80002aa8:	64e2                	ld	s1,24(sp)
    80002aaa:	6942                	ld	s2,16(sp)
    80002aac:	69a2                	ld	s3,8(sp)
    80002aae:	6145                	addi	sp,sp,48
    80002ab0:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002ab2:	00006517          	auipc	a0,0x6
    80002ab6:	97650513          	addi	a0,a0,-1674 # 80008428 <states.0+0xc8>
    80002aba:	ffffe097          	auipc	ra,0xffffe
    80002abe:	a86080e7          	jalr	-1402(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002ac2:	00006517          	auipc	a0,0x6
    80002ac6:	98e50513          	addi	a0,a0,-1650 # 80008450 <states.0+0xf0>
    80002aca:	ffffe097          	auipc	ra,0xffffe
    80002ace:	a76080e7          	jalr	-1418(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002ad2:	85ce                	mv	a1,s3
    80002ad4:	00006517          	auipc	a0,0x6
    80002ad8:	99c50513          	addi	a0,a0,-1636 # 80008470 <states.0+0x110>
    80002adc:	ffffe097          	auipc	ra,0xffffe
    80002ae0:	aae080e7          	jalr	-1362(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ae4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ae8:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002aec:	00006517          	auipc	a0,0x6
    80002af0:	99450513          	addi	a0,a0,-1644 # 80008480 <states.0+0x120>
    80002af4:	ffffe097          	auipc	ra,0xffffe
    80002af8:	a96080e7          	jalr	-1386(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002afc:	00006517          	auipc	a0,0x6
    80002b00:	99c50513          	addi	a0,a0,-1636 # 80008498 <states.0+0x138>
    80002b04:	ffffe097          	auipc	ra,0xffffe
    80002b08:	a3c080e7          	jalr	-1476(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b0c:	fffff097          	auipc	ra,0xfffff
    80002b10:	ea0080e7          	jalr	-352(ra) # 800019ac <myproc>
    80002b14:	d541                	beqz	a0,80002a9c <kerneltrap+0x38>
    80002b16:	fffff097          	auipc	ra,0xfffff
    80002b1a:	e96080e7          	jalr	-362(ra) # 800019ac <myproc>
    80002b1e:	4d18                	lw	a4,24(a0)
    80002b20:	4791                	li	a5,4
    80002b22:	f6f71de3          	bne	a4,a5,80002a9c <kerneltrap+0x38>
    yield();
    80002b26:	fffff097          	auipc	ra,0xfffff
    80002b2a:	504080e7          	jalr	1284(ra) # 8000202a <yield>
    80002b2e:	b7bd                	j	80002a9c <kerneltrap+0x38>

0000000080002b30 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b30:	1101                	addi	sp,sp,-32
    80002b32:	ec06                	sd	ra,24(sp)
    80002b34:	e822                	sd	s0,16(sp)
    80002b36:	e426                	sd	s1,8(sp)
    80002b38:	1000                	addi	s0,sp,32
    80002b3a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b3c:	fffff097          	auipc	ra,0xfffff
    80002b40:	e70080e7          	jalr	-400(ra) # 800019ac <myproc>
  switch (n) {
    80002b44:	4795                	li	a5,5
    80002b46:	0497e163          	bltu	a5,s1,80002b88 <argraw+0x58>
    80002b4a:	048a                	slli	s1,s1,0x2
    80002b4c:	00006717          	auipc	a4,0x6
    80002b50:	98470713          	addi	a4,a4,-1660 # 800084d0 <states.0+0x170>
    80002b54:	94ba                	add	s1,s1,a4
    80002b56:	409c                	lw	a5,0(s1)
    80002b58:	97ba                	add	a5,a5,a4
    80002b5a:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b5c:	6d3c                	ld	a5,88(a0)
    80002b5e:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b60:	60e2                	ld	ra,24(sp)
    80002b62:	6442                	ld	s0,16(sp)
    80002b64:	64a2                	ld	s1,8(sp)
    80002b66:	6105                	addi	sp,sp,32
    80002b68:	8082                	ret
    return p->trapframe->a1;
    80002b6a:	6d3c                	ld	a5,88(a0)
    80002b6c:	7fa8                	ld	a0,120(a5)
    80002b6e:	bfcd                	j	80002b60 <argraw+0x30>
    return p->trapframe->a2;
    80002b70:	6d3c                	ld	a5,88(a0)
    80002b72:	63c8                	ld	a0,128(a5)
    80002b74:	b7f5                	j	80002b60 <argraw+0x30>
    return p->trapframe->a3;
    80002b76:	6d3c                	ld	a5,88(a0)
    80002b78:	67c8                	ld	a0,136(a5)
    80002b7a:	b7dd                	j	80002b60 <argraw+0x30>
    return p->trapframe->a4;
    80002b7c:	6d3c                	ld	a5,88(a0)
    80002b7e:	6bc8                	ld	a0,144(a5)
    80002b80:	b7c5                	j	80002b60 <argraw+0x30>
    return p->trapframe->a5;
    80002b82:	6d3c                	ld	a5,88(a0)
    80002b84:	6fc8                	ld	a0,152(a5)
    80002b86:	bfe9                	j	80002b60 <argraw+0x30>
  panic("argraw");
    80002b88:	00006517          	auipc	a0,0x6
    80002b8c:	92050513          	addi	a0,a0,-1760 # 800084a8 <states.0+0x148>
    80002b90:	ffffe097          	auipc	ra,0xffffe
    80002b94:	9b0080e7          	jalr	-1616(ra) # 80000540 <panic>

0000000080002b98 <fetchaddr>:
{
    80002b98:	1101                	addi	sp,sp,-32
    80002b9a:	ec06                	sd	ra,24(sp)
    80002b9c:	e822                	sd	s0,16(sp)
    80002b9e:	e426                	sd	s1,8(sp)
    80002ba0:	e04a                	sd	s2,0(sp)
    80002ba2:	1000                	addi	s0,sp,32
    80002ba4:	84aa                	mv	s1,a0
    80002ba6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ba8:	fffff097          	auipc	ra,0xfffff
    80002bac:	e04080e7          	jalr	-508(ra) # 800019ac <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002bb0:	653c                	ld	a5,72(a0)
    80002bb2:	02f4f863          	bgeu	s1,a5,80002be2 <fetchaddr+0x4a>
    80002bb6:	00848713          	addi	a4,s1,8
    80002bba:	02e7e663          	bltu	a5,a4,80002be6 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002bbe:	46a1                	li	a3,8
    80002bc0:	8626                	mv	a2,s1
    80002bc2:	85ca                	mv	a1,s2
    80002bc4:	6928                	ld	a0,80(a0)
    80002bc6:	fffff097          	auipc	ra,0xfffff
    80002bca:	b32080e7          	jalr	-1230(ra) # 800016f8 <copyin>
    80002bce:	00a03533          	snez	a0,a0
    80002bd2:	40a00533          	neg	a0,a0
}
    80002bd6:	60e2                	ld	ra,24(sp)
    80002bd8:	6442                	ld	s0,16(sp)
    80002bda:	64a2                	ld	s1,8(sp)
    80002bdc:	6902                	ld	s2,0(sp)
    80002bde:	6105                	addi	sp,sp,32
    80002be0:	8082                	ret
    return -1;
    80002be2:	557d                	li	a0,-1
    80002be4:	bfcd                	j	80002bd6 <fetchaddr+0x3e>
    80002be6:	557d                	li	a0,-1
    80002be8:	b7fd                	j	80002bd6 <fetchaddr+0x3e>

0000000080002bea <fetchstr>:
{
    80002bea:	7179                	addi	sp,sp,-48
    80002bec:	f406                	sd	ra,40(sp)
    80002bee:	f022                	sd	s0,32(sp)
    80002bf0:	ec26                	sd	s1,24(sp)
    80002bf2:	e84a                	sd	s2,16(sp)
    80002bf4:	e44e                	sd	s3,8(sp)
    80002bf6:	1800                	addi	s0,sp,48
    80002bf8:	892a                	mv	s2,a0
    80002bfa:	84ae                	mv	s1,a1
    80002bfc:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002bfe:	fffff097          	auipc	ra,0xfffff
    80002c02:	dae080e7          	jalr	-594(ra) # 800019ac <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002c06:	86ce                	mv	a3,s3
    80002c08:	864a                	mv	a2,s2
    80002c0a:	85a6                	mv	a1,s1
    80002c0c:	6928                	ld	a0,80(a0)
    80002c0e:	fffff097          	auipc	ra,0xfffff
    80002c12:	b78080e7          	jalr	-1160(ra) # 80001786 <copyinstr>
    80002c16:	00054e63          	bltz	a0,80002c32 <fetchstr+0x48>
  return strlen(buf);
    80002c1a:	8526                	mv	a0,s1
    80002c1c:	ffffe097          	auipc	ra,0xffffe
    80002c20:	232080e7          	jalr	562(ra) # 80000e4e <strlen>
}
    80002c24:	70a2                	ld	ra,40(sp)
    80002c26:	7402                	ld	s0,32(sp)
    80002c28:	64e2                	ld	s1,24(sp)
    80002c2a:	6942                	ld	s2,16(sp)
    80002c2c:	69a2                	ld	s3,8(sp)
    80002c2e:	6145                	addi	sp,sp,48
    80002c30:	8082                	ret
    return -1;
    80002c32:	557d                	li	a0,-1
    80002c34:	bfc5                	j	80002c24 <fetchstr+0x3a>

0000000080002c36 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002c36:	1101                	addi	sp,sp,-32
    80002c38:	ec06                	sd	ra,24(sp)
    80002c3a:	e822                	sd	s0,16(sp)
    80002c3c:	e426                	sd	s1,8(sp)
    80002c3e:	1000                	addi	s0,sp,32
    80002c40:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c42:	00000097          	auipc	ra,0x0
    80002c46:	eee080e7          	jalr	-274(ra) # 80002b30 <argraw>
    80002c4a:	c088                	sw	a0,0(s1)
}
    80002c4c:	60e2                	ld	ra,24(sp)
    80002c4e:	6442                	ld	s0,16(sp)
    80002c50:	64a2                	ld	s1,8(sp)
    80002c52:	6105                	addi	sp,sp,32
    80002c54:	8082                	ret

0000000080002c56 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002c56:	1101                	addi	sp,sp,-32
    80002c58:	ec06                	sd	ra,24(sp)
    80002c5a:	e822                	sd	s0,16(sp)
    80002c5c:	e426                	sd	s1,8(sp)
    80002c5e:	1000                	addi	s0,sp,32
    80002c60:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c62:	00000097          	auipc	ra,0x0
    80002c66:	ece080e7          	jalr	-306(ra) # 80002b30 <argraw>
    80002c6a:	e088                	sd	a0,0(s1)
}
    80002c6c:	60e2                	ld	ra,24(sp)
    80002c6e:	6442                	ld	s0,16(sp)
    80002c70:	64a2                	ld	s1,8(sp)
    80002c72:	6105                	addi	sp,sp,32
    80002c74:	8082                	ret

0000000080002c76 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c76:	7179                	addi	sp,sp,-48
    80002c78:	f406                	sd	ra,40(sp)
    80002c7a:	f022                	sd	s0,32(sp)
    80002c7c:	ec26                	sd	s1,24(sp)
    80002c7e:	e84a                	sd	s2,16(sp)
    80002c80:	1800                	addi	s0,sp,48
    80002c82:	84ae                	mv	s1,a1
    80002c84:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002c86:	fd840593          	addi	a1,s0,-40
    80002c8a:	00000097          	auipc	ra,0x0
    80002c8e:	fcc080e7          	jalr	-52(ra) # 80002c56 <argaddr>
  return fetchstr(addr, buf, max);
    80002c92:	864a                	mv	a2,s2
    80002c94:	85a6                	mv	a1,s1
    80002c96:	fd843503          	ld	a0,-40(s0)
    80002c9a:	00000097          	auipc	ra,0x0
    80002c9e:	f50080e7          	jalr	-176(ra) # 80002bea <fetchstr>
}
    80002ca2:	70a2                	ld	ra,40(sp)
    80002ca4:	7402                	ld	s0,32(sp)
    80002ca6:	64e2                	ld	s1,24(sp)
    80002ca8:	6942                	ld	s2,16(sp)
    80002caa:	6145                	addi	sp,sp,48
    80002cac:	8082                	ret

0000000080002cae <syscall>:
[SYS_procs]   sys_procs,
};

void
syscall(void)
{
    80002cae:	1101                	addi	sp,sp,-32
    80002cb0:	ec06                	sd	ra,24(sp)
    80002cb2:	e822                	sd	s0,16(sp)
    80002cb4:	e426                	sd	s1,8(sp)
    80002cb6:	e04a                	sd	s2,0(sp)
    80002cb8:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002cba:	fffff097          	auipc	ra,0xfffff
    80002cbe:	cf2080e7          	jalr	-782(ra) # 800019ac <myproc>
    80002cc2:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002cc4:	05853903          	ld	s2,88(a0)
    80002cc8:	0a893783          	ld	a5,168(s2)
    80002ccc:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002cd0:	37fd                	addiw	a5,a5,-1
    80002cd2:	4759                	li	a4,22
    80002cd4:	00f76f63          	bltu	a4,a5,80002cf2 <syscall+0x44>
    80002cd8:	00369713          	slli	a4,a3,0x3
    80002cdc:	00006797          	auipc	a5,0x6
    80002ce0:	80c78793          	addi	a5,a5,-2036 # 800084e8 <syscalls>
    80002ce4:	97ba                	add	a5,a5,a4
    80002ce6:	639c                	ld	a5,0(a5)
    80002ce8:	c789                	beqz	a5,80002cf2 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002cea:	9782                	jalr	a5
    80002cec:	06a93823          	sd	a0,112(s2)
    80002cf0:	a839                	j	80002d0e <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002cf2:	15848613          	addi	a2,s1,344
    80002cf6:	588c                	lw	a1,48(s1)
    80002cf8:	00005517          	auipc	a0,0x5
    80002cfc:	7b850513          	addi	a0,a0,1976 # 800084b0 <states.0+0x150>
    80002d00:	ffffe097          	auipc	ra,0xffffe
    80002d04:	88a080e7          	jalr	-1910(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d08:	6cbc                	ld	a5,88(s1)
    80002d0a:	577d                	li	a4,-1
    80002d0c:	fbb8                	sd	a4,112(a5)
  }
}
    80002d0e:	60e2                	ld	ra,24(sp)
    80002d10:	6442                	ld	s0,16(sp)
    80002d12:	64a2                	ld	s1,8(sp)
    80002d14:	6902                	ld	s2,0(sp)
    80002d16:	6105                	addi	sp,sp,32
    80002d18:	8082                	ret

0000000080002d1a <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002d1a:	1101                	addi	sp,sp,-32
    80002d1c:	ec06                	sd	ra,24(sp)
    80002d1e:	e822                	sd	s0,16(sp)
    80002d20:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002d22:	fec40593          	addi	a1,s0,-20
    80002d26:	4501                	li	a0,0
    80002d28:	00000097          	auipc	ra,0x0
    80002d2c:	f0e080e7          	jalr	-242(ra) # 80002c36 <argint>
  exit(n);
    80002d30:	fec42503          	lw	a0,-20(s0)
    80002d34:	fffff097          	auipc	ra,0xfffff
    80002d38:	466080e7          	jalr	1126(ra) # 8000219a <exit>
  return 0;  // not reached
}
    80002d3c:	4501                	li	a0,0
    80002d3e:	60e2                	ld	ra,24(sp)
    80002d40:	6442                	ld	s0,16(sp)
    80002d42:	6105                	addi	sp,sp,32
    80002d44:	8082                	ret

0000000080002d46 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d46:	1141                	addi	sp,sp,-16
    80002d48:	e406                	sd	ra,8(sp)
    80002d4a:	e022                	sd	s0,0(sp)
    80002d4c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d4e:	fffff097          	auipc	ra,0xfffff
    80002d52:	c5e080e7          	jalr	-930(ra) # 800019ac <myproc>
}
    80002d56:	5908                	lw	a0,48(a0)
    80002d58:	60a2                	ld	ra,8(sp)
    80002d5a:	6402                	ld	s0,0(sp)
    80002d5c:	0141                	addi	sp,sp,16
    80002d5e:	8082                	ret

0000000080002d60 <sys_fork>:

uint64
sys_fork(void)
{
    80002d60:	1141                	addi	sp,sp,-16
    80002d62:	e406                	sd	ra,8(sp)
    80002d64:	e022                	sd	s0,0(sp)
    80002d66:	0800                	addi	s0,sp,16
  return fork();
    80002d68:	fffff097          	auipc	ra,0xfffff
    80002d6c:	000080e7          	jalr	ra # 80001d68 <fork>
}
    80002d70:	60a2                	ld	ra,8(sp)
    80002d72:	6402                	ld	s0,0(sp)
    80002d74:	0141                	addi	sp,sp,16
    80002d76:	8082                	ret

0000000080002d78 <sys_wait>:

uint64
sys_wait(void)
{
    80002d78:	1101                	addi	sp,sp,-32
    80002d7a:	ec06                	sd	ra,24(sp)
    80002d7c:	e822                	sd	s0,16(sp)
    80002d7e:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002d80:	fe840593          	addi	a1,s0,-24
    80002d84:	4501                	li	a0,0
    80002d86:	00000097          	auipc	ra,0x0
    80002d8a:	ed0080e7          	jalr	-304(ra) # 80002c56 <argaddr>
  return wait(p);
    80002d8e:	fe843503          	ld	a0,-24(s0)
    80002d92:	fffff097          	auipc	ra,0xfffff
    80002d96:	5ae080e7          	jalr	1454(ra) # 80002340 <wait>
}
    80002d9a:	60e2                	ld	ra,24(sp)
    80002d9c:	6442                	ld	s0,16(sp)
    80002d9e:	6105                	addi	sp,sp,32
    80002da0:	8082                	ret

0000000080002da2 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002da2:	7179                	addi	sp,sp,-48
    80002da4:	f406                	sd	ra,40(sp)
    80002da6:	f022                	sd	s0,32(sp)
    80002da8:	ec26                	sd	s1,24(sp)
    80002daa:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002dac:	fdc40593          	addi	a1,s0,-36
    80002db0:	4501                	li	a0,0
    80002db2:	00000097          	auipc	ra,0x0
    80002db6:	e84080e7          	jalr	-380(ra) # 80002c36 <argint>
  addr = myproc()->sz;
    80002dba:	fffff097          	auipc	ra,0xfffff
    80002dbe:	bf2080e7          	jalr	-1038(ra) # 800019ac <myproc>
    80002dc2:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002dc4:	fdc42503          	lw	a0,-36(s0)
    80002dc8:	fffff097          	auipc	ra,0xfffff
    80002dcc:	f44080e7          	jalr	-188(ra) # 80001d0c <growproc>
    80002dd0:	00054863          	bltz	a0,80002de0 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002dd4:	8526                	mv	a0,s1
    80002dd6:	70a2                	ld	ra,40(sp)
    80002dd8:	7402                	ld	s0,32(sp)
    80002dda:	64e2                	ld	s1,24(sp)
    80002ddc:	6145                	addi	sp,sp,48
    80002dde:	8082                	ret
    return -1;
    80002de0:	54fd                	li	s1,-1
    80002de2:	bfcd                	j	80002dd4 <sys_sbrk+0x32>

0000000080002de4 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002de4:	7139                	addi	sp,sp,-64
    80002de6:	fc06                	sd	ra,56(sp)
    80002de8:	f822                	sd	s0,48(sp)
    80002dea:	f426                	sd	s1,40(sp)
    80002dec:	f04a                	sd	s2,32(sp)
    80002dee:	ec4e                	sd	s3,24(sp)
    80002df0:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002df2:	fcc40593          	addi	a1,s0,-52
    80002df6:	4501                	li	a0,0
    80002df8:	00000097          	auipc	ra,0x0
    80002dfc:	e3e080e7          	jalr	-450(ra) # 80002c36 <argint>
  acquire(&tickslock);
    80002e00:	00014517          	auipc	a0,0x14
    80002e04:	e3050513          	addi	a0,a0,-464 # 80016c30 <tickslock>
    80002e08:	ffffe097          	auipc	ra,0xffffe
    80002e0c:	dce080e7          	jalr	-562(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002e10:	00006917          	auipc	s2,0x6
    80002e14:	b8092903          	lw	s2,-1152(s2) # 80008990 <ticks>
  while(ticks - ticks0 < n){
    80002e18:	fcc42783          	lw	a5,-52(s0)
    80002e1c:	cf9d                	beqz	a5,80002e5a <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e1e:	00014997          	auipc	s3,0x14
    80002e22:	e1298993          	addi	s3,s3,-494 # 80016c30 <tickslock>
    80002e26:	00006497          	auipc	s1,0x6
    80002e2a:	b6a48493          	addi	s1,s1,-1174 # 80008990 <ticks>
    if(killed(myproc())){
    80002e2e:	fffff097          	auipc	ra,0xfffff
    80002e32:	b7e080e7          	jalr	-1154(ra) # 800019ac <myproc>
    80002e36:	fffff097          	auipc	ra,0xfffff
    80002e3a:	4d8080e7          	jalr	1240(ra) # 8000230e <killed>
    80002e3e:	ed15                	bnez	a0,80002e7a <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002e40:	85ce                	mv	a1,s3
    80002e42:	8526                	mv	a0,s1
    80002e44:	fffff097          	auipc	ra,0xfffff
    80002e48:	222080e7          	jalr	546(ra) # 80002066 <sleep>
  while(ticks - ticks0 < n){
    80002e4c:	409c                	lw	a5,0(s1)
    80002e4e:	412787bb          	subw	a5,a5,s2
    80002e52:	fcc42703          	lw	a4,-52(s0)
    80002e56:	fce7ece3          	bltu	a5,a4,80002e2e <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002e5a:	00014517          	auipc	a0,0x14
    80002e5e:	dd650513          	addi	a0,a0,-554 # 80016c30 <tickslock>
    80002e62:	ffffe097          	auipc	ra,0xffffe
    80002e66:	e28080e7          	jalr	-472(ra) # 80000c8a <release>
  return 0;
    80002e6a:	4501                	li	a0,0
}
    80002e6c:	70e2                	ld	ra,56(sp)
    80002e6e:	7442                	ld	s0,48(sp)
    80002e70:	74a2                	ld	s1,40(sp)
    80002e72:	7902                	ld	s2,32(sp)
    80002e74:	69e2                	ld	s3,24(sp)
    80002e76:	6121                	addi	sp,sp,64
    80002e78:	8082                	ret
      release(&tickslock);
    80002e7a:	00014517          	auipc	a0,0x14
    80002e7e:	db650513          	addi	a0,a0,-586 # 80016c30 <tickslock>
    80002e82:	ffffe097          	auipc	ra,0xffffe
    80002e86:	e08080e7          	jalr	-504(ra) # 80000c8a <release>
      return -1;
    80002e8a:	557d                	li	a0,-1
    80002e8c:	b7c5                	j	80002e6c <sys_sleep+0x88>

0000000080002e8e <sys_kill>:

uint64
sys_kill(void)
{
    80002e8e:	1101                	addi	sp,sp,-32
    80002e90:	ec06                	sd	ra,24(sp)
    80002e92:	e822                	sd	s0,16(sp)
    80002e94:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002e96:	fec40593          	addi	a1,s0,-20
    80002e9a:	4501                	li	a0,0
    80002e9c:	00000097          	auipc	ra,0x0
    80002ea0:	d9a080e7          	jalr	-614(ra) # 80002c36 <argint>
  return kill(pid);
    80002ea4:	fec42503          	lw	a0,-20(s0)
    80002ea8:	fffff097          	auipc	ra,0xfffff
    80002eac:	3c8080e7          	jalr	968(ra) # 80002270 <kill>
}
    80002eb0:	60e2                	ld	ra,24(sp)
    80002eb2:	6442                	ld	s0,16(sp)
    80002eb4:	6105                	addi	sp,sp,32
    80002eb6:	8082                	ret

0000000080002eb8 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002eb8:	1101                	addi	sp,sp,-32
    80002eba:	ec06                	sd	ra,24(sp)
    80002ebc:	e822                	sd	s0,16(sp)
    80002ebe:	e426                	sd	s1,8(sp)
    80002ec0:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002ec2:	00014517          	auipc	a0,0x14
    80002ec6:	d6e50513          	addi	a0,a0,-658 # 80016c30 <tickslock>
    80002eca:	ffffe097          	auipc	ra,0xffffe
    80002ece:	d0c080e7          	jalr	-756(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80002ed2:	00006497          	auipc	s1,0x6
    80002ed6:	abe4a483          	lw	s1,-1346(s1) # 80008990 <ticks>
  release(&tickslock);
    80002eda:	00014517          	auipc	a0,0x14
    80002ede:	d5650513          	addi	a0,a0,-682 # 80016c30 <tickslock>
    80002ee2:	ffffe097          	auipc	ra,0xffffe
    80002ee6:	da8080e7          	jalr	-600(ra) # 80000c8a <release>
  return xticks;
}
    80002eea:	02049513          	slli	a0,s1,0x20
    80002eee:	9101                	srli	a0,a0,0x20
    80002ef0:	60e2                	ld	ra,24(sp)
    80002ef2:	6442                	ld	s0,16(sp)
    80002ef4:	64a2                	ld	s1,8(sp)
    80002ef6:	6105                	addi	sp,sp,32
    80002ef8:	8082                	ret

0000000080002efa <sys_procs>:
uint64 sys_procs(void)
{
    80002efa:	1141                	addi	sp,sp,-16
    80002efc:	e406                	sd	ra,8(sp)
    80002efe:	e022                	sd	s0,0(sp)
    80002f00:	0800                	addi	s0,sp,16
  return procs();
    80002f02:	fffff097          	auipc	ra,0xfffff
    80002f06:	73e080e7          	jalr	1854(ra) # 80002640 <procs>
}
    80002f0a:	60a2                	ld	ra,8(sp)
    80002f0c:	6402                	ld	s0,0(sp)
    80002f0e:	0141                	addi	sp,sp,16
    80002f10:	8082                	ret

0000000080002f12 <sys_chprio>:

uint64 sys_chprio(void)
{
    80002f12:	1101                	addi	sp,sp,-32
    80002f14:	ec06                	sd	ra,24(sp)
    80002f16:	e822                	sd	s0,16(sp)
    80002f18:	1000                	addi	s0,sp,32
  int pid, priority;
  argint(0, &pid);
    80002f1a:	fec40593          	addi	a1,s0,-20
    80002f1e:	4501                	li	a0,0
    80002f20:	00000097          	auipc	ra,0x0
    80002f24:	d16080e7          	jalr	-746(ra) # 80002c36 <argint>
    if (pid<0)
    80002f28:	fec42783          	lw	a5,-20(s0)
    return -1;
    80002f2c:	557d                	li	a0,-1
    if (pid<0)
    80002f2e:	0207c463          	bltz	a5,80002f56 <sys_chprio+0x44>
  argint(1, &priority);
    80002f32:	fe840593          	addi	a1,s0,-24
    80002f36:	4505                	li	a0,1
    80002f38:	00000097          	auipc	ra,0x0
    80002f3c:	cfe080e7          	jalr	-770(ra) # 80002c36 <argint>
    if(priority <0)
    80002f40:	fe842583          	lw	a1,-24(s0)
    return -1;
    80002f44:	557d                	li	a0,-1
    if(priority <0)
    80002f46:	0005c863          	bltz	a1,80002f56 <sys_chprio+0x44>
  return chprio(pid, priority);
    80002f4a:	fec42503          	lw	a0,-20(s0)
    80002f4e:	fffff097          	auipc	ra,0xfffff
    80002f52:	67c080e7          	jalr	1660(ra) # 800025ca <chprio>
}
    80002f56:	60e2                	ld	ra,24(sp)
    80002f58:	6442                	ld	s0,16(sp)
    80002f5a:	6105                	addi	sp,sp,32
    80002f5c:	8082                	ret

0000000080002f5e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f5e:	7179                	addi	sp,sp,-48
    80002f60:	f406                	sd	ra,40(sp)
    80002f62:	f022                	sd	s0,32(sp)
    80002f64:	ec26                	sd	s1,24(sp)
    80002f66:	e84a                	sd	s2,16(sp)
    80002f68:	e44e                	sd	s3,8(sp)
    80002f6a:	e052                	sd	s4,0(sp)
    80002f6c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f6e:	00005597          	auipc	a1,0x5
    80002f72:	63a58593          	addi	a1,a1,1594 # 800085a8 <syscalls+0xc0>
    80002f76:	00014517          	auipc	a0,0x14
    80002f7a:	cd250513          	addi	a0,a0,-814 # 80016c48 <bcache>
    80002f7e:	ffffe097          	auipc	ra,0xffffe
    80002f82:	bc8080e7          	jalr	-1080(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f86:	0001c797          	auipc	a5,0x1c
    80002f8a:	cc278793          	addi	a5,a5,-830 # 8001ec48 <bcache+0x8000>
    80002f8e:	0001c717          	auipc	a4,0x1c
    80002f92:	f2270713          	addi	a4,a4,-222 # 8001eeb0 <bcache+0x8268>
    80002f96:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f9a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f9e:	00014497          	auipc	s1,0x14
    80002fa2:	cc248493          	addi	s1,s1,-830 # 80016c60 <bcache+0x18>
    b->next = bcache.head.next;
    80002fa6:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002fa8:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002faa:	00005a17          	auipc	s4,0x5
    80002fae:	606a0a13          	addi	s4,s4,1542 # 800085b0 <syscalls+0xc8>
    b->next = bcache.head.next;
    80002fb2:	2b893783          	ld	a5,696(s2)
    80002fb6:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002fb8:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002fbc:	85d2                	mv	a1,s4
    80002fbe:	01048513          	addi	a0,s1,16
    80002fc2:	00001097          	auipc	ra,0x1
    80002fc6:	4c8080e7          	jalr	1224(ra) # 8000448a <initsleeplock>
    bcache.head.next->prev = b;
    80002fca:	2b893783          	ld	a5,696(s2)
    80002fce:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002fd0:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002fd4:	45848493          	addi	s1,s1,1112
    80002fd8:	fd349de3          	bne	s1,s3,80002fb2 <binit+0x54>
  }
}
    80002fdc:	70a2                	ld	ra,40(sp)
    80002fde:	7402                	ld	s0,32(sp)
    80002fe0:	64e2                	ld	s1,24(sp)
    80002fe2:	6942                	ld	s2,16(sp)
    80002fe4:	69a2                	ld	s3,8(sp)
    80002fe6:	6a02                	ld	s4,0(sp)
    80002fe8:	6145                	addi	sp,sp,48
    80002fea:	8082                	ret

0000000080002fec <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002fec:	7179                	addi	sp,sp,-48
    80002fee:	f406                	sd	ra,40(sp)
    80002ff0:	f022                	sd	s0,32(sp)
    80002ff2:	ec26                	sd	s1,24(sp)
    80002ff4:	e84a                	sd	s2,16(sp)
    80002ff6:	e44e                	sd	s3,8(sp)
    80002ff8:	1800                	addi	s0,sp,48
    80002ffa:	892a                	mv	s2,a0
    80002ffc:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002ffe:	00014517          	auipc	a0,0x14
    80003002:	c4a50513          	addi	a0,a0,-950 # 80016c48 <bcache>
    80003006:	ffffe097          	auipc	ra,0xffffe
    8000300a:	bd0080e7          	jalr	-1072(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000300e:	0001c497          	auipc	s1,0x1c
    80003012:	ef24b483          	ld	s1,-270(s1) # 8001ef00 <bcache+0x82b8>
    80003016:	0001c797          	auipc	a5,0x1c
    8000301a:	e9a78793          	addi	a5,a5,-358 # 8001eeb0 <bcache+0x8268>
    8000301e:	02f48f63          	beq	s1,a5,8000305c <bread+0x70>
    80003022:	873e                	mv	a4,a5
    80003024:	a021                	j	8000302c <bread+0x40>
    80003026:	68a4                	ld	s1,80(s1)
    80003028:	02e48a63          	beq	s1,a4,8000305c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000302c:	449c                	lw	a5,8(s1)
    8000302e:	ff279ce3          	bne	a5,s2,80003026 <bread+0x3a>
    80003032:	44dc                	lw	a5,12(s1)
    80003034:	ff3799e3          	bne	a5,s3,80003026 <bread+0x3a>
      b->refcnt++;
    80003038:	40bc                	lw	a5,64(s1)
    8000303a:	2785                	addiw	a5,a5,1
    8000303c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000303e:	00014517          	auipc	a0,0x14
    80003042:	c0a50513          	addi	a0,a0,-1014 # 80016c48 <bcache>
    80003046:	ffffe097          	auipc	ra,0xffffe
    8000304a:	c44080e7          	jalr	-956(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    8000304e:	01048513          	addi	a0,s1,16
    80003052:	00001097          	auipc	ra,0x1
    80003056:	472080e7          	jalr	1138(ra) # 800044c4 <acquiresleep>
      return b;
    8000305a:	a8b9                	j	800030b8 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000305c:	0001c497          	auipc	s1,0x1c
    80003060:	e9c4b483          	ld	s1,-356(s1) # 8001eef8 <bcache+0x82b0>
    80003064:	0001c797          	auipc	a5,0x1c
    80003068:	e4c78793          	addi	a5,a5,-436 # 8001eeb0 <bcache+0x8268>
    8000306c:	00f48863          	beq	s1,a5,8000307c <bread+0x90>
    80003070:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003072:	40bc                	lw	a5,64(s1)
    80003074:	cf81                	beqz	a5,8000308c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003076:	64a4                	ld	s1,72(s1)
    80003078:	fee49de3          	bne	s1,a4,80003072 <bread+0x86>
  panic("bget: no buffers");
    8000307c:	00005517          	auipc	a0,0x5
    80003080:	53c50513          	addi	a0,a0,1340 # 800085b8 <syscalls+0xd0>
    80003084:	ffffd097          	auipc	ra,0xffffd
    80003088:	4bc080e7          	jalr	1212(ra) # 80000540 <panic>
      b->dev = dev;
    8000308c:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003090:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003094:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003098:	4785                	li	a5,1
    8000309a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000309c:	00014517          	auipc	a0,0x14
    800030a0:	bac50513          	addi	a0,a0,-1108 # 80016c48 <bcache>
    800030a4:	ffffe097          	auipc	ra,0xffffe
    800030a8:	be6080e7          	jalr	-1050(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    800030ac:	01048513          	addi	a0,s1,16
    800030b0:	00001097          	auipc	ra,0x1
    800030b4:	414080e7          	jalr	1044(ra) # 800044c4 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800030b8:	409c                	lw	a5,0(s1)
    800030ba:	cb89                	beqz	a5,800030cc <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800030bc:	8526                	mv	a0,s1
    800030be:	70a2                	ld	ra,40(sp)
    800030c0:	7402                	ld	s0,32(sp)
    800030c2:	64e2                	ld	s1,24(sp)
    800030c4:	6942                	ld	s2,16(sp)
    800030c6:	69a2                	ld	s3,8(sp)
    800030c8:	6145                	addi	sp,sp,48
    800030ca:	8082                	ret
    virtio_disk_rw(b, 0);
    800030cc:	4581                	li	a1,0
    800030ce:	8526                	mv	a0,s1
    800030d0:	00003097          	auipc	ra,0x3
    800030d4:	fe2080e7          	jalr	-30(ra) # 800060b2 <virtio_disk_rw>
    b->valid = 1;
    800030d8:	4785                	li	a5,1
    800030da:	c09c                	sw	a5,0(s1)
  return b;
    800030dc:	b7c5                	j	800030bc <bread+0xd0>

00000000800030de <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800030de:	1101                	addi	sp,sp,-32
    800030e0:	ec06                	sd	ra,24(sp)
    800030e2:	e822                	sd	s0,16(sp)
    800030e4:	e426                	sd	s1,8(sp)
    800030e6:	1000                	addi	s0,sp,32
    800030e8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030ea:	0541                	addi	a0,a0,16
    800030ec:	00001097          	auipc	ra,0x1
    800030f0:	472080e7          	jalr	1138(ra) # 8000455e <holdingsleep>
    800030f4:	cd01                	beqz	a0,8000310c <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800030f6:	4585                	li	a1,1
    800030f8:	8526                	mv	a0,s1
    800030fa:	00003097          	auipc	ra,0x3
    800030fe:	fb8080e7          	jalr	-72(ra) # 800060b2 <virtio_disk_rw>
}
    80003102:	60e2                	ld	ra,24(sp)
    80003104:	6442                	ld	s0,16(sp)
    80003106:	64a2                	ld	s1,8(sp)
    80003108:	6105                	addi	sp,sp,32
    8000310a:	8082                	ret
    panic("bwrite");
    8000310c:	00005517          	auipc	a0,0x5
    80003110:	4c450513          	addi	a0,a0,1220 # 800085d0 <syscalls+0xe8>
    80003114:	ffffd097          	auipc	ra,0xffffd
    80003118:	42c080e7          	jalr	1068(ra) # 80000540 <panic>

000000008000311c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000311c:	1101                	addi	sp,sp,-32
    8000311e:	ec06                	sd	ra,24(sp)
    80003120:	e822                	sd	s0,16(sp)
    80003122:	e426                	sd	s1,8(sp)
    80003124:	e04a                	sd	s2,0(sp)
    80003126:	1000                	addi	s0,sp,32
    80003128:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000312a:	01050913          	addi	s2,a0,16
    8000312e:	854a                	mv	a0,s2
    80003130:	00001097          	auipc	ra,0x1
    80003134:	42e080e7          	jalr	1070(ra) # 8000455e <holdingsleep>
    80003138:	c92d                	beqz	a0,800031aa <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000313a:	854a                	mv	a0,s2
    8000313c:	00001097          	auipc	ra,0x1
    80003140:	3de080e7          	jalr	990(ra) # 8000451a <releasesleep>

  acquire(&bcache.lock);
    80003144:	00014517          	auipc	a0,0x14
    80003148:	b0450513          	addi	a0,a0,-1276 # 80016c48 <bcache>
    8000314c:	ffffe097          	auipc	ra,0xffffe
    80003150:	a8a080e7          	jalr	-1398(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003154:	40bc                	lw	a5,64(s1)
    80003156:	37fd                	addiw	a5,a5,-1
    80003158:	0007871b          	sext.w	a4,a5
    8000315c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000315e:	eb05                	bnez	a4,8000318e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003160:	68bc                	ld	a5,80(s1)
    80003162:	64b8                	ld	a4,72(s1)
    80003164:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003166:	64bc                	ld	a5,72(s1)
    80003168:	68b8                	ld	a4,80(s1)
    8000316a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000316c:	0001c797          	auipc	a5,0x1c
    80003170:	adc78793          	addi	a5,a5,-1316 # 8001ec48 <bcache+0x8000>
    80003174:	2b87b703          	ld	a4,696(a5)
    80003178:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000317a:	0001c717          	auipc	a4,0x1c
    8000317e:	d3670713          	addi	a4,a4,-714 # 8001eeb0 <bcache+0x8268>
    80003182:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003184:	2b87b703          	ld	a4,696(a5)
    80003188:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000318a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000318e:	00014517          	auipc	a0,0x14
    80003192:	aba50513          	addi	a0,a0,-1350 # 80016c48 <bcache>
    80003196:	ffffe097          	auipc	ra,0xffffe
    8000319a:	af4080e7          	jalr	-1292(ra) # 80000c8a <release>
}
    8000319e:	60e2                	ld	ra,24(sp)
    800031a0:	6442                	ld	s0,16(sp)
    800031a2:	64a2                	ld	s1,8(sp)
    800031a4:	6902                	ld	s2,0(sp)
    800031a6:	6105                	addi	sp,sp,32
    800031a8:	8082                	ret
    panic("brelse");
    800031aa:	00005517          	auipc	a0,0x5
    800031ae:	42e50513          	addi	a0,a0,1070 # 800085d8 <syscalls+0xf0>
    800031b2:	ffffd097          	auipc	ra,0xffffd
    800031b6:	38e080e7          	jalr	910(ra) # 80000540 <panic>

00000000800031ba <bpin>:

void
bpin(struct buf *b) {
    800031ba:	1101                	addi	sp,sp,-32
    800031bc:	ec06                	sd	ra,24(sp)
    800031be:	e822                	sd	s0,16(sp)
    800031c0:	e426                	sd	s1,8(sp)
    800031c2:	1000                	addi	s0,sp,32
    800031c4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031c6:	00014517          	auipc	a0,0x14
    800031ca:	a8250513          	addi	a0,a0,-1406 # 80016c48 <bcache>
    800031ce:	ffffe097          	auipc	ra,0xffffe
    800031d2:	a08080e7          	jalr	-1528(ra) # 80000bd6 <acquire>
  b->refcnt++;
    800031d6:	40bc                	lw	a5,64(s1)
    800031d8:	2785                	addiw	a5,a5,1
    800031da:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031dc:	00014517          	auipc	a0,0x14
    800031e0:	a6c50513          	addi	a0,a0,-1428 # 80016c48 <bcache>
    800031e4:	ffffe097          	auipc	ra,0xffffe
    800031e8:	aa6080e7          	jalr	-1370(ra) # 80000c8a <release>
}
    800031ec:	60e2                	ld	ra,24(sp)
    800031ee:	6442                	ld	s0,16(sp)
    800031f0:	64a2                	ld	s1,8(sp)
    800031f2:	6105                	addi	sp,sp,32
    800031f4:	8082                	ret

00000000800031f6 <bunpin>:

void
bunpin(struct buf *b) {
    800031f6:	1101                	addi	sp,sp,-32
    800031f8:	ec06                	sd	ra,24(sp)
    800031fa:	e822                	sd	s0,16(sp)
    800031fc:	e426                	sd	s1,8(sp)
    800031fe:	1000                	addi	s0,sp,32
    80003200:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003202:	00014517          	auipc	a0,0x14
    80003206:	a4650513          	addi	a0,a0,-1466 # 80016c48 <bcache>
    8000320a:	ffffe097          	auipc	ra,0xffffe
    8000320e:	9cc080e7          	jalr	-1588(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003212:	40bc                	lw	a5,64(s1)
    80003214:	37fd                	addiw	a5,a5,-1
    80003216:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003218:	00014517          	auipc	a0,0x14
    8000321c:	a3050513          	addi	a0,a0,-1488 # 80016c48 <bcache>
    80003220:	ffffe097          	auipc	ra,0xffffe
    80003224:	a6a080e7          	jalr	-1430(ra) # 80000c8a <release>
}
    80003228:	60e2                	ld	ra,24(sp)
    8000322a:	6442                	ld	s0,16(sp)
    8000322c:	64a2                	ld	s1,8(sp)
    8000322e:	6105                	addi	sp,sp,32
    80003230:	8082                	ret

0000000080003232 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003232:	1101                	addi	sp,sp,-32
    80003234:	ec06                	sd	ra,24(sp)
    80003236:	e822                	sd	s0,16(sp)
    80003238:	e426                	sd	s1,8(sp)
    8000323a:	e04a                	sd	s2,0(sp)
    8000323c:	1000                	addi	s0,sp,32
    8000323e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003240:	00d5d59b          	srliw	a1,a1,0xd
    80003244:	0001c797          	auipc	a5,0x1c
    80003248:	0e07a783          	lw	a5,224(a5) # 8001f324 <sb+0x1c>
    8000324c:	9dbd                	addw	a1,a1,a5
    8000324e:	00000097          	auipc	ra,0x0
    80003252:	d9e080e7          	jalr	-610(ra) # 80002fec <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003256:	0074f713          	andi	a4,s1,7
    8000325a:	4785                	li	a5,1
    8000325c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003260:	14ce                	slli	s1,s1,0x33
    80003262:	90d9                	srli	s1,s1,0x36
    80003264:	00950733          	add	a4,a0,s1
    80003268:	05874703          	lbu	a4,88(a4)
    8000326c:	00e7f6b3          	and	a3,a5,a4
    80003270:	c69d                	beqz	a3,8000329e <bfree+0x6c>
    80003272:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003274:	94aa                	add	s1,s1,a0
    80003276:	fff7c793          	not	a5,a5
    8000327a:	8f7d                	and	a4,a4,a5
    8000327c:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003280:	00001097          	auipc	ra,0x1
    80003284:	126080e7          	jalr	294(ra) # 800043a6 <log_write>
  brelse(bp);
    80003288:	854a                	mv	a0,s2
    8000328a:	00000097          	auipc	ra,0x0
    8000328e:	e92080e7          	jalr	-366(ra) # 8000311c <brelse>
}
    80003292:	60e2                	ld	ra,24(sp)
    80003294:	6442                	ld	s0,16(sp)
    80003296:	64a2                	ld	s1,8(sp)
    80003298:	6902                	ld	s2,0(sp)
    8000329a:	6105                	addi	sp,sp,32
    8000329c:	8082                	ret
    panic("freeing free block");
    8000329e:	00005517          	auipc	a0,0x5
    800032a2:	34250513          	addi	a0,a0,834 # 800085e0 <syscalls+0xf8>
    800032a6:	ffffd097          	auipc	ra,0xffffd
    800032aa:	29a080e7          	jalr	666(ra) # 80000540 <panic>

00000000800032ae <balloc>:
{
    800032ae:	711d                	addi	sp,sp,-96
    800032b0:	ec86                	sd	ra,88(sp)
    800032b2:	e8a2                	sd	s0,80(sp)
    800032b4:	e4a6                	sd	s1,72(sp)
    800032b6:	e0ca                	sd	s2,64(sp)
    800032b8:	fc4e                	sd	s3,56(sp)
    800032ba:	f852                	sd	s4,48(sp)
    800032bc:	f456                	sd	s5,40(sp)
    800032be:	f05a                	sd	s6,32(sp)
    800032c0:	ec5e                	sd	s7,24(sp)
    800032c2:	e862                	sd	s8,16(sp)
    800032c4:	e466                	sd	s9,8(sp)
    800032c6:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800032c8:	0001c797          	auipc	a5,0x1c
    800032cc:	0447a783          	lw	a5,68(a5) # 8001f30c <sb+0x4>
    800032d0:	cff5                	beqz	a5,800033cc <balloc+0x11e>
    800032d2:	8baa                	mv	s7,a0
    800032d4:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800032d6:	0001cb17          	auipc	s6,0x1c
    800032da:	032b0b13          	addi	s6,s6,50 # 8001f308 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032de:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800032e0:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032e2:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800032e4:	6c89                	lui	s9,0x2
    800032e6:	a061                	j	8000336e <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    800032e8:	97ca                	add	a5,a5,s2
    800032ea:	8e55                	or	a2,a2,a3
    800032ec:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800032f0:	854a                	mv	a0,s2
    800032f2:	00001097          	auipc	ra,0x1
    800032f6:	0b4080e7          	jalr	180(ra) # 800043a6 <log_write>
        brelse(bp);
    800032fa:	854a                	mv	a0,s2
    800032fc:	00000097          	auipc	ra,0x0
    80003300:	e20080e7          	jalr	-480(ra) # 8000311c <brelse>
  bp = bread(dev, bno);
    80003304:	85a6                	mv	a1,s1
    80003306:	855e                	mv	a0,s7
    80003308:	00000097          	auipc	ra,0x0
    8000330c:	ce4080e7          	jalr	-796(ra) # 80002fec <bread>
    80003310:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003312:	40000613          	li	a2,1024
    80003316:	4581                	li	a1,0
    80003318:	05850513          	addi	a0,a0,88
    8000331c:	ffffe097          	auipc	ra,0xffffe
    80003320:	9b6080e7          	jalr	-1610(ra) # 80000cd2 <memset>
  log_write(bp);
    80003324:	854a                	mv	a0,s2
    80003326:	00001097          	auipc	ra,0x1
    8000332a:	080080e7          	jalr	128(ra) # 800043a6 <log_write>
  brelse(bp);
    8000332e:	854a                	mv	a0,s2
    80003330:	00000097          	auipc	ra,0x0
    80003334:	dec080e7          	jalr	-532(ra) # 8000311c <brelse>
}
    80003338:	8526                	mv	a0,s1
    8000333a:	60e6                	ld	ra,88(sp)
    8000333c:	6446                	ld	s0,80(sp)
    8000333e:	64a6                	ld	s1,72(sp)
    80003340:	6906                	ld	s2,64(sp)
    80003342:	79e2                	ld	s3,56(sp)
    80003344:	7a42                	ld	s4,48(sp)
    80003346:	7aa2                	ld	s5,40(sp)
    80003348:	7b02                	ld	s6,32(sp)
    8000334a:	6be2                	ld	s7,24(sp)
    8000334c:	6c42                	ld	s8,16(sp)
    8000334e:	6ca2                	ld	s9,8(sp)
    80003350:	6125                	addi	sp,sp,96
    80003352:	8082                	ret
    brelse(bp);
    80003354:	854a                	mv	a0,s2
    80003356:	00000097          	auipc	ra,0x0
    8000335a:	dc6080e7          	jalr	-570(ra) # 8000311c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000335e:	015c87bb          	addw	a5,s9,s5
    80003362:	00078a9b          	sext.w	s5,a5
    80003366:	004b2703          	lw	a4,4(s6)
    8000336a:	06eaf163          	bgeu	s5,a4,800033cc <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    8000336e:	41fad79b          	sraiw	a5,s5,0x1f
    80003372:	0137d79b          	srliw	a5,a5,0x13
    80003376:	015787bb          	addw	a5,a5,s5
    8000337a:	40d7d79b          	sraiw	a5,a5,0xd
    8000337e:	01cb2583          	lw	a1,28(s6)
    80003382:	9dbd                	addw	a1,a1,a5
    80003384:	855e                	mv	a0,s7
    80003386:	00000097          	auipc	ra,0x0
    8000338a:	c66080e7          	jalr	-922(ra) # 80002fec <bread>
    8000338e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003390:	004b2503          	lw	a0,4(s6)
    80003394:	000a849b          	sext.w	s1,s5
    80003398:	8762                	mv	a4,s8
    8000339a:	faa4fde3          	bgeu	s1,a0,80003354 <balloc+0xa6>
      m = 1 << (bi % 8);
    8000339e:	00777693          	andi	a3,a4,7
    800033a2:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800033a6:	41f7579b          	sraiw	a5,a4,0x1f
    800033aa:	01d7d79b          	srliw	a5,a5,0x1d
    800033ae:	9fb9                	addw	a5,a5,a4
    800033b0:	4037d79b          	sraiw	a5,a5,0x3
    800033b4:	00f90633          	add	a2,s2,a5
    800033b8:	05864603          	lbu	a2,88(a2)
    800033bc:	00c6f5b3          	and	a1,a3,a2
    800033c0:	d585                	beqz	a1,800032e8 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033c2:	2705                	addiw	a4,a4,1
    800033c4:	2485                	addiw	s1,s1,1
    800033c6:	fd471ae3          	bne	a4,s4,8000339a <balloc+0xec>
    800033ca:	b769                	j	80003354 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    800033cc:	00005517          	auipc	a0,0x5
    800033d0:	22c50513          	addi	a0,a0,556 # 800085f8 <syscalls+0x110>
    800033d4:	ffffd097          	auipc	ra,0xffffd
    800033d8:	1b6080e7          	jalr	438(ra) # 8000058a <printf>
  return 0;
    800033dc:	4481                	li	s1,0
    800033de:	bfa9                	j	80003338 <balloc+0x8a>

00000000800033e0 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800033e0:	7179                	addi	sp,sp,-48
    800033e2:	f406                	sd	ra,40(sp)
    800033e4:	f022                	sd	s0,32(sp)
    800033e6:	ec26                	sd	s1,24(sp)
    800033e8:	e84a                	sd	s2,16(sp)
    800033ea:	e44e                	sd	s3,8(sp)
    800033ec:	e052                	sd	s4,0(sp)
    800033ee:	1800                	addi	s0,sp,48
    800033f0:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800033f2:	47ad                	li	a5,11
    800033f4:	02b7e863          	bltu	a5,a1,80003424 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    800033f8:	02059793          	slli	a5,a1,0x20
    800033fc:	01e7d593          	srli	a1,a5,0x1e
    80003400:	00b504b3          	add	s1,a0,a1
    80003404:	0504a903          	lw	s2,80(s1)
    80003408:	06091e63          	bnez	s2,80003484 <bmap+0xa4>
      addr = balloc(ip->dev);
    8000340c:	4108                	lw	a0,0(a0)
    8000340e:	00000097          	auipc	ra,0x0
    80003412:	ea0080e7          	jalr	-352(ra) # 800032ae <balloc>
    80003416:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000341a:	06090563          	beqz	s2,80003484 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    8000341e:	0524a823          	sw	s2,80(s1)
    80003422:	a08d                	j	80003484 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003424:	ff45849b          	addiw	s1,a1,-12
    80003428:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000342c:	0ff00793          	li	a5,255
    80003430:	08e7e563          	bltu	a5,a4,800034ba <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003434:	08052903          	lw	s2,128(a0)
    80003438:	00091d63          	bnez	s2,80003452 <bmap+0x72>
      addr = balloc(ip->dev);
    8000343c:	4108                	lw	a0,0(a0)
    8000343e:	00000097          	auipc	ra,0x0
    80003442:	e70080e7          	jalr	-400(ra) # 800032ae <balloc>
    80003446:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000344a:	02090d63          	beqz	s2,80003484 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000344e:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003452:	85ca                	mv	a1,s2
    80003454:	0009a503          	lw	a0,0(s3)
    80003458:	00000097          	auipc	ra,0x0
    8000345c:	b94080e7          	jalr	-1132(ra) # 80002fec <bread>
    80003460:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003462:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003466:	02049713          	slli	a4,s1,0x20
    8000346a:	01e75593          	srli	a1,a4,0x1e
    8000346e:	00b784b3          	add	s1,a5,a1
    80003472:	0004a903          	lw	s2,0(s1)
    80003476:	02090063          	beqz	s2,80003496 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000347a:	8552                	mv	a0,s4
    8000347c:	00000097          	auipc	ra,0x0
    80003480:	ca0080e7          	jalr	-864(ra) # 8000311c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003484:	854a                	mv	a0,s2
    80003486:	70a2                	ld	ra,40(sp)
    80003488:	7402                	ld	s0,32(sp)
    8000348a:	64e2                	ld	s1,24(sp)
    8000348c:	6942                	ld	s2,16(sp)
    8000348e:	69a2                	ld	s3,8(sp)
    80003490:	6a02                	ld	s4,0(sp)
    80003492:	6145                	addi	sp,sp,48
    80003494:	8082                	ret
      addr = balloc(ip->dev);
    80003496:	0009a503          	lw	a0,0(s3)
    8000349a:	00000097          	auipc	ra,0x0
    8000349e:	e14080e7          	jalr	-492(ra) # 800032ae <balloc>
    800034a2:	0005091b          	sext.w	s2,a0
      if(addr){
    800034a6:	fc090ae3          	beqz	s2,8000347a <bmap+0x9a>
        a[bn] = addr;
    800034aa:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800034ae:	8552                	mv	a0,s4
    800034b0:	00001097          	auipc	ra,0x1
    800034b4:	ef6080e7          	jalr	-266(ra) # 800043a6 <log_write>
    800034b8:	b7c9                	j	8000347a <bmap+0x9a>
  panic("bmap: out of range");
    800034ba:	00005517          	auipc	a0,0x5
    800034be:	15650513          	addi	a0,a0,342 # 80008610 <syscalls+0x128>
    800034c2:	ffffd097          	auipc	ra,0xffffd
    800034c6:	07e080e7          	jalr	126(ra) # 80000540 <panic>

00000000800034ca <iget>:
{
    800034ca:	7179                	addi	sp,sp,-48
    800034cc:	f406                	sd	ra,40(sp)
    800034ce:	f022                	sd	s0,32(sp)
    800034d0:	ec26                	sd	s1,24(sp)
    800034d2:	e84a                	sd	s2,16(sp)
    800034d4:	e44e                	sd	s3,8(sp)
    800034d6:	e052                	sd	s4,0(sp)
    800034d8:	1800                	addi	s0,sp,48
    800034da:	89aa                	mv	s3,a0
    800034dc:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800034de:	0001c517          	auipc	a0,0x1c
    800034e2:	e4a50513          	addi	a0,a0,-438 # 8001f328 <itable>
    800034e6:	ffffd097          	auipc	ra,0xffffd
    800034ea:	6f0080e7          	jalr	1776(ra) # 80000bd6 <acquire>
  empty = 0;
    800034ee:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800034f0:	0001c497          	auipc	s1,0x1c
    800034f4:	e5048493          	addi	s1,s1,-432 # 8001f340 <itable+0x18>
    800034f8:	0001e697          	auipc	a3,0x1e
    800034fc:	8d868693          	addi	a3,a3,-1832 # 80020dd0 <log>
    80003500:	a039                	j	8000350e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003502:	02090b63          	beqz	s2,80003538 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003506:	08848493          	addi	s1,s1,136
    8000350a:	02d48a63          	beq	s1,a3,8000353e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000350e:	449c                	lw	a5,8(s1)
    80003510:	fef059e3          	blez	a5,80003502 <iget+0x38>
    80003514:	4098                	lw	a4,0(s1)
    80003516:	ff3716e3          	bne	a4,s3,80003502 <iget+0x38>
    8000351a:	40d8                	lw	a4,4(s1)
    8000351c:	ff4713e3          	bne	a4,s4,80003502 <iget+0x38>
      ip->ref++;
    80003520:	2785                	addiw	a5,a5,1
    80003522:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003524:	0001c517          	auipc	a0,0x1c
    80003528:	e0450513          	addi	a0,a0,-508 # 8001f328 <itable>
    8000352c:	ffffd097          	auipc	ra,0xffffd
    80003530:	75e080e7          	jalr	1886(ra) # 80000c8a <release>
      return ip;
    80003534:	8926                	mv	s2,s1
    80003536:	a03d                	j	80003564 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003538:	f7f9                	bnez	a5,80003506 <iget+0x3c>
    8000353a:	8926                	mv	s2,s1
    8000353c:	b7e9                	j	80003506 <iget+0x3c>
  if(empty == 0)
    8000353e:	02090c63          	beqz	s2,80003576 <iget+0xac>
  ip->dev = dev;
    80003542:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003546:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000354a:	4785                	li	a5,1
    8000354c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003550:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003554:	0001c517          	auipc	a0,0x1c
    80003558:	dd450513          	addi	a0,a0,-556 # 8001f328 <itable>
    8000355c:	ffffd097          	auipc	ra,0xffffd
    80003560:	72e080e7          	jalr	1838(ra) # 80000c8a <release>
}
    80003564:	854a                	mv	a0,s2
    80003566:	70a2                	ld	ra,40(sp)
    80003568:	7402                	ld	s0,32(sp)
    8000356a:	64e2                	ld	s1,24(sp)
    8000356c:	6942                	ld	s2,16(sp)
    8000356e:	69a2                	ld	s3,8(sp)
    80003570:	6a02                	ld	s4,0(sp)
    80003572:	6145                	addi	sp,sp,48
    80003574:	8082                	ret
    panic("iget: no inodes");
    80003576:	00005517          	auipc	a0,0x5
    8000357a:	0b250513          	addi	a0,a0,178 # 80008628 <syscalls+0x140>
    8000357e:	ffffd097          	auipc	ra,0xffffd
    80003582:	fc2080e7          	jalr	-62(ra) # 80000540 <panic>

0000000080003586 <fsinit>:
fsinit(int dev) {
    80003586:	7179                	addi	sp,sp,-48
    80003588:	f406                	sd	ra,40(sp)
    8000358a:	f022                	sd	s0,32(sp)
    8000358c:	ec26                	sd	s1,24(sp)
    8000358e:	e84a                	sd	s2,16(sp)
    80003590:	e44e                	sd	s3,8(sp)
    80003592:	1800                	addi	s0,sp,48
    80003594:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003596:	4585                	li	a1,1
    80003598:	00000097          	auipc	ra,0x0
    8000359c:	a54080e7          	jalr	-1452(ra) # 80002fec <bread>
    800035a0:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800035a2:	0001c997          	auipc	s3,0x1c
    800035a6:	d6698993          	addi	s3,s3,-666 # 8001f308 <sb>
    800035aa:	02000613          	li	a2,32
    800035ae:	05850593          	addi	a1,a0,88
    800035b2:	854e                	mv	a0,s3
    800035b4:	ffffd097          	auipc	ra,0xffffd
    800035b8:	77a080e7          	jalr	1914(ra) # 80000d2e <memmove>
  brelse(bp);
    800035bc:	8526                	mv	a0,s1
    800035be:	00000097          	auipc	ra,0x0
    800035c2:	b5e080e7          	jalr	-1186(ra) # 8000311c <brelse>
  if(sb.magic != FSMAGIC)
    800035c6:	0009a703          	lw	a4,0(s3)
    800035ca:	102037b7          	lui	a5,0x10203
    800035ce:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800035d2:	02f71263          	bne	a4,a5,800035f6 <fsinit+0x70>
  initlog(dev, &sb);
    800035d6:	0001c597          	auipc	a1,0x1c
    800035da:	d3258593          	addi	a1,a1,-718 # 8001f308 <sb>
    800035de:	854a                	mv	a0,s2
    800035e0:	00001097          	auipc	ra,0x1
    800035e4:	b4a080e7          	jalr	-1206(ra) # 8000412a <initlog>
}
    800035e8:	70a2                	ld	ra,40(sp)
    800035ea:	7402                	ld	s0,32(sp)
    800035ec:	64e2                	ld	s1,24(sp)
    800035ee:	6942                	ld	s2,16(sp)
    800035f0:	69a2                	ld	s3,8(sp)
    800035f2:	6145                	addi	sp,sp,48
    800035f4:	8082                	ret
    panic("invalid file system");
    800035f6:	00005517          	auipc	a0,0x5
    800035fa:	04250513          	addi	a0,a0,66 # 80008638 <syscalls+0x150>
    800035fe:	ffffd097          	auipc	ra,0xffffd
    80003602:	f42080e7          	jalr	-190(ra) # 80000540 <panic>

0000000080003606 <iinit>:
{
    80003606:	7179                	addi	sp,sp,-48
    80003608:	f406                	sd	ra,40(sp)
    8000360a:	f022                	sd	s0,32(sp)
    8000360c:	ec26                	sd	s1,24(sp)
    8000360e:	e84a                	sd	s2,16(sp)
    80003610:	e44e                	sd	s3,8(sp)
    80003612:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003614:	00005597          	auipc	a1,0x5
    80003618:	03c58593          	addi	a1,a1,60 # 80008650 <syscalls+0x168>
    8000361c:	0001c517          	auipc	a0,0x1c
    80003620:	d0c50513          	addi	a0,a0,-756 # 8001f328 <itable>
    80003624:	ffffd097          	auipc	ra,0xffffd
    80003628:	522080e7          	jalr	1314(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000362c:	0001c497          	auipc	s1,0x1c
    80003630:	d2448493          	addi	s1,s1,-732 # 8001f350 <itable+0x28>
    80003634:	0001d997          	auipc	s3,0x1d
    80003638:	7ac98993          	addi	s3,s3,1964 # 80020de0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000363c:	00005917          	auipc	s2,0x5
    80003640:	01c90913          	addi	s2,s2,28 # 80008658 <syscalls+0x170>
    80003644:	85ca                	mv	a1,s2
    80003646:	8526                	mv	a0,s1
    80003648:	00001097          	auipc	ra,0x1
    8000364c:	e42080e7          	jalr	-446(ra) # 8000448a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003650:	08848493          	addi	s1,s1,136
    80003654:	ff3498e3          	bne	s1,s3,80003644 <iinit+0x3e>
}
    80003658:	70a2                	ld	ra,40(sp)
    8000365a:	7402                	ld	s0,32(sp)
    8000365c:	64e2                	ld	s1,24(sp)
    8000365e:	6942                	ld	s2,16(sp)
    80003660:	69a2                	ld	s3,8(sp)
    80003662:	6145                	addi	sp,sp,48
    80003664:	8082                	ret

0000000080003666 <ialloc>:
{
    80003666:	715d                	addi	sp,sp,-80
    80003668:	e486                	sd	ra,72(sp)
    8000366a:	e0a2                	sd	s0,64(sp)
    8000366c:	fc26                	sd	s1,56(sp)
    8000366e:	f84a                	sd	s2,48(sp)
    80003670:	f44e                	sd	s3,40(sp)
    80003672:	f052                	sd	s4,32(sp)
    80003674:	ec56                	sd	s5,24(sp)
    80003676:	e85a                	sd	s6,16(sp)
    80003678:	e45e                	sd	s7,8(sp)
    8000367a:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000367c:	0001c717          	auipc	a4,0x1c
    80003680:	c9872703          	lw	a4,-872(a4) # 8001f314 <sb+0xc>
    80003684:	4785                	li	a5,1
    80003686:	04e7fa63          	bgeu	a5,a4,800036da <ialloc+0x74>
    8000368a:	8aaa                	mv	s5,a0
    8000368c:	8bae                	mv	s7,a1
    8000368e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003690:	0001ca17          	auipc	s4,0x1c
    80003694:	c78a0a13          	addi	s4,s4,-904 # 8001f308 <sb>
    80003698:	00048b1b          	sext.w	s6,s1
    8000369c:	0044d593          	srli	a1,s1,0x4
    800036a0:	018a2783          	lw	a5,24(s4)
    800036a4:	9dbd                	addw	a1,a1,a5
    800036a6:	8556                	mv	a0,s5
    800036a8:	00000097          	auipc	ra,0x0
    800036ac:	944080e7          	jalr	-1724(ra) # 80002fec <bread>
    800036b0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800036b2:	05850993          	addi	s3,a0,88
    800036b6:	00f4f793          	andi	a5,s1,15
    800036ba:	079a                	slli	a5,a5,0x6
    800036bc:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800036be:	00099783          	lh	a5,0(s3)
    800036c2:	c3a1                	beqz	a5,80003702 <ialloc+0x9c>
    brelse(bp);
    800036c4:	00000097          	auipc	ra,0x0
    800036c8:	a58080e7          	jalr	-1448(ra) # 8000311c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800036cc:	0485                	addi	s1,s1,1
    800036ce:	00ca2703          	lw	a4,12(s4)
    800036d2:	0004879b          	sext.w	a5,s1
    800036d6:	fce7e1e3          	bltu	a5,a4,80003698 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    800036da:	00005517          	auipc	a0,0x5
    800036de:	f8650513          	addi	a0,a0,-122 # 80008660 <syscalls+0x178>
    800036e2:	ffffd097          	auipc	ra,0xffffd
    800036e6:	ea8080e7          	jalr	-344(ra) # 8000058a <printf>
  return 0;
    800036ea:	4501                	li	a0,0
}
    800036ec:	60a6                	ld	ra,72(sp)
    800036ee:	6406                	ld	s0,64(sp)
    800036f0:	74e2                	ld	s1,56(sp)
    800036f2:	7942                	ld	s2,48(sp)
    800036f4:	79a2                	ld	s3,40(sp)
    800036f6:	7a02                	ld	s4,32(sp)
    800036f8:	6ae2                	ld	s5,24(sp)
    800036fa:	6b42                	ld	s6,16(sp)
    800036fc:	6ba2                	ld	s7,8(sp)
    800036fe:	6161                	addi	sp,sp,80
    80003700:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003702:	04000613          	li	a2,64
    80003706:	4581                	li	a1,0
    80003708:	854e                	mv	a0,s3
    8000370a:	ffffd097          	auipc	ra,0xffffd
    8000370e:	5c8080e7          	jalr	1480(ra) # 80000cd2 <memset>
      dip->type = type;
    80003712:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003716:	854a                	mv	a0,s2
    80003718:	00001097          	auipc	ra,0x1
    8000371c:	c8e080e7          	jalr	-882(ra) # 800043a6 <log_write>
      brelse(bp);
    80003720:	854a                	mv	a0,s2
    80003722:	00000097          	auipc	ra,0x0
    80003726:	9fa080e7          	jalr	-1542(ra) # 8000311c <brelse>
      return iget(dev, inum);
    8000372a:	85da                	mv	a1,s6
    8000372c:	8556                	mv	a0,s5
    8000372e:	00000097          	auipc	ra,0x0
    80003732:	d9c080e7          	jalr	-612(ra) # 800034ca <iget>
    80003736:	bf5d                	j	800036ec <ialloc+0x86>

0000000080003738 <iupdate>:
{
    80003738:	1101                	addi	sp,sp,-32
    8000373a:	ec06                	sd	ra,24(sp)
    8000373c:	e822                	sd	s0,16(sp)
    8000373e:	e426                	sd	s1,8(sp)
    80003740:	e04a                	sd	s2,0(sp)
    80003742:	1000                	addi	s0,sp,32
    80003744:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003746:	415c                	lw	a5,4(a0)
    80003748:	0047d79b          	srliw	a5,a5,0x4
    8000374c:	0001c597          	auipc	a1,0x1c
    80003750:	bd45a583          	lw	a1,-1068(a1) # 8001f320 <sb+0x18>
    80003754:	9dbd                	addw	a1,a1,a5
    80003756:	4108                	lw	a0,0(a0)
    80003758:	00000097          	auipc	ra,0x0
    8000375c:	894080e7          	jalr	-1900(ra) # 80002fec <bread>
    80003760:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003762:	05850793          	addi	a5,a0,88
    80003766:	40d8                	lw	a4,4(s1)
    80003768:	8b3d                	andi	a4,a4,15
    8000376a:	071a                	slli	a4,a4,0x6
    8000376c:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    8000376e:	04449703          	lh	a4,68(s1)
    80003772:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003776:	04649703          	lh	a4,70(s1)
    8000377a:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    8000377e:	04849703          	lh	a4,72(s1)
    80003782:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003786:	04a49703          	lh	a4,74(s1)
    8000378a:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    8000378e:	44f8                	lw	a4,76(s1)
    80003790:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003792:	03400613          	li	a2,52
    80003796:	05048593          	addi	a1,s1,80
    8000379a:	00c78513          	addi	a0,a5,12
    8000379e:	ffffd097          	auipc	ra,0xffffd
    800037a2:	590080e7          	jalr	1424(ra) # 80000d2e <memmove>
  log_write(bp);
    800037a6:	854a                	mv	a0,s2
    800037a8:	00001097          	auipc	ra,0x1
    800037ac:	bfe080e7          	jalr	-1026(ra) # 800043a6 <log_write>
  brelse(bp);
    800037b0:	854a                	mv	a0,s2
    800037b2:	00000097          	auipc	ra,0x0
    800037b6:	96a080e7          	jalr	-1686(ra) # 8000311c <brelse>
}
    800037ba:	60e2                	ld	ra,24(sp)
    800037bc:	6442                	ld	s0,16(sp)
    800037be:	64a2                	ld	s1,8(sp)
    800037c0:	6902                	ld	s2,0(sp)
    800037c2:	6105                	addi	sp,sp,32
    800037c4:	8082                	ret

00000000800037c6 <idup>:
{
    800037c6:	1101                	addi	sp,sp,-32
    800037c8:	ec06                	sd	ra,24(sp)
    800037ca:	e822                	sd	s0,16(sp)
    800037cc:	e426                	sd	s1,8(sp)
    800037ce:	1000                	addi	s0,sp,32
    800037d0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800037d2:	0001c517          	auipc	a0,0x1c
    800037d6:	b5650513          	addi	a0,a0,-1194 # 8001f328 <itable>
    800037da:	ffffd097          	auipc	ra,0xffffd
    800037de:	3fc080e7          	jalr	1020(ra) # 80000bd6 <acquire>
  ip->ref++;
    800037e2:	449c                	lw	a5,8(s1)
    800037e4:	2785                	addiw	a5,a5,1
    800037e6:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800037e8:	0001c517          	auipc	a0,0x1c
    800037ec:	b4050513          	addi	a0,a0,-1216 # 8001f328 <itable>
    800037f0:	ffffd097          	auipc	ra,0xffffd
    800037f4:	49a080e7          	jalr	1178(ra) # 80000c8a <release>
}
    800037f8:	8526                	mv	a0,s1
    800037fa:	60e2                	ld	ra,24(sp)
    800037fc:	6442                	ld	s0,16(sp)
    800037fe:	64a2                	ld	s1,8(sp)
    80003800:	6105                	addi	sp,sp,32
    80003802:	8082                	ret

0000000080003804 <ilock>:
{
    80003804:	1101                	addi	sp,sp,-32
    80003806:	ec06                	sd	ra,24(sp)
    80003808:	e822                	sd	s0,16(sp)
    8000380a:	e426                	sd	s1,8(sp)
    8000380c:	e04a                	sd	s2,0(sp)
    8000380e:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003810:	c115                	beqz	a0,80003834 <ilock+0x30>
    80003812:	84aa                	mv	s1,a0
    80003814:	451c                	lw	a5,8(a0)
    80003816:	00f05f63          	blez	a5,80003834 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000381a:	0541                	addi	a0,a0,16
    8000381c:	00001097          	auipc	ra,0x1
    80003820:	ca8080e7          	jalr	-856(ra) # 800044c4 <acquiresleep>
  if(ip->valid == 0){
    80003824:	40bc                	lw	a5,64(s1)
    80003826:	cf99                	beqz	a5,80003844 <ilock+0x40>
}
    80003828:	60e2                	ld	ra,24(sp)
    8000382a:	6442                	ld	s0,16(sp)
    8000382c:	64a2                	ld	s1,8(sp)
    8000382e:	6902                	ld	s2,0(sp)
    80003830:	6105                	addi	sp,sp,32
    80003832:	8082                	ret
    panic("ilock");
    80003834:	00005517          	auipc	a0,0x5
    80003838:	e4450513          	addi	a0,a0,-444 # 80008678 <syscalls+0x190>
    8000383c:	ffffd097          	auipc	ra,0xffffd
    80003840:	d04080e7          	jalr	-764(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003844:	40dc                	lw	a5,4(s1)
    80003846:	0047d79b          	srliw	a5,a5,0x4
    8000384a:	0001c597          	auipc	a1,0x1c
    8000384e:	ad65a583          	lw	a1,-1322(a1) # 8001f320 <sb+0x18>
    80003852:	9dbd                	addw	a1,a1,a5
    80003854:	4088                	lw	a0,0(s1)
    80003856:	fffff097          	auipc	ra,0xfffff
    8000385a:	796080e7          	jalr	1942(ra) # 80002fec <bread>
    8000385e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003860:	05850593          	addi	a1,a0,88
    80003864:	40dc                	lw	a5,4(s1)
    80003866:	8bbd                	andi	a5,a5,15
    80003868:	079a                	slli	a5,a5,0x6
    8000386a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000386c:	00059783          	lh	a5,0(a1)
    80003870:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003874:	00259783          	lh	a5,2(a1)
    80003878:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000387c:	00459783          	lh	a5,4(a1)
    80003880:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003884:	00659783          	lh	a5,6(a1)
    80003888:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000388c:	459c                	lw	a5,8(a1)
    8000388e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003890:	03400613          	li	a2,52
    80003894:	05b1                	addi	a1,a1,12
    80003896:	05048513          	addi	a0,s1,80
    8000389a:	ffffd097          	auipc	ra,0xffffd
    8000389e:	494080e7          	jalr	1172(ra) # 80000d2e <memmove>
    brelse(bp);
    800038a2:	854a                	mv	a0,s2
    800038a4:	00000097          	auipc	ra,0x0
    800038a8:	878080e7          	jalr	-1928(ra) # 8000311c <brelse>
    ip->valid = 1;
    800038ac:	4785                	li	a5,1
    800038ae:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800038b0:	04449783          	lh	a5,68(s1)
    800038b4:	fbb5                	bnez	a5,80003828 <ilock+0x24>
      panic("ilock: no type");
    800038b6:	00005517          	auipc	a0,0x5
    800038ba:	dca50513          	addi	a0,a0,-566 # 80008680 <syscalls+0x198>
    800038be:	ffffd097          	auipc	ra,0xffffd
    800038c2:	c82080e7          	jalr	-894(ra) # 80000540 <panic>

00000000800038c6 <iunlock>:
{
    800038c6:	1101                	addi	sp,sp,-32
    800038c8:	ec06                	sd	ra,24(sp)
    800038ca:	e822                	sd	s0,16(sp)
    800038cc:	e426                	sd	s1,8(sp)
    800038ce:	e04a                	sd	s2,0(sp)
    800038d0:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800038d2:	c905                	beqz	a0,80003902 <iunlock+0x3c>
    800038d4:	84aa                	mv	s1,a0
    800038d6:	01050913          	addi	s2,a0,16
    800038da:	854a                	mv	a0,s2
    800038dc:	00001097          	auipc	ra,0x1
    800038e0:	c82080e7          	jalr	-894(ra) # 8000455e <holdingsleep>
    800038e4:	cd19                	beqz	a0,80003902 <iunlock+0x3c>
    800038e6:	449c                	lw	a5,8(s1)
    800038e8:	00f05d63          	blez	a5,80003902 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800038ec:	854a                	mv	a0,s2
    800038ee:	00001097          	auipc	ra,0x1
    800038f2:	c2c080e7          	jalr	-980(ra) # 8000451a <releasesleep>
}
    800038f6:	60e2                	ld	ra,24(sp)
    800038f8:	6442                	ld	s0,16(sp)
    800038fa:	64a2                	ld	s1,8(sp)
    800038fc:	6902                	ld	s2,0(sp)
    800038fe:	6105                	addi	sp,sp,32
    80003900:	8082                	ret
    panic("iunlock");
    80003902:	00005517          	auipc	a0,0x5
    80003906:	d8e50513          	addi	a0,a0,-626 # 80008690 <syscalls+0x1a8>
    8000390a:	ffffd097          	auipc	ra,0xffffd
    8000390e:	c36080e7          	jalr	-970(ra) # 80000540 <panic>

0000000080003912 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003912:	7179                	addi	sp,sp,-48
    80003914:	f406                	sd	ra,40(sp)
    80003916:	f022                	sd	s0,32(sp)
    80003918:	ec26                	sd	s1,24(sp)
    8000391a:	e84a                	sd	s2,16(sp)
    8000391c:	e44e                	sd	s3,8(sp)
    8000391e:	e052                	sd	s4,0(sp)
    80003920:	1800                	addi	s0,sp,48
    80003922:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003924:	05050493          	addi	s1,a0,80
    80003928:	08050913          	addi	s2,a0,128
    8000392c:	a021                	j	80003934 <itrunc+0x22>
    8000392e:	0491                	addi	s1,s1,4
    80003930:	01248d63          	beq	s1,s2,8000394a <itrunc+0x38>
    if(ip->addrs[i]){
    80003934:	408c                	lw	a1,0(s1)
    80003936:	dde5                	beqz	a1,8000392e <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003938:	0009a503          	lw	a0,0(s3)
    8000393c:	00000097          	auipc	ra,0x0
    80003940:	8f6080e7          	jalr	-1802(ra) # 80003232 <bfree>
      ip->addrs[i] = 0;
    80003944:	0004a023          	sw	zero,0(s1)
    80003948:	b7dd                	j	8000392e <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000394a:	0809a583          	lw	a1,128(s3)
    8000394e:	e185                	bnez	a1,8000396e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003950:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003954:	854e                	mv	a0,s3
    80003956:	00000097          	auipc	ra,0x0
    8000395a:	de2080e7          	jalr	-542(ra) # 80003738 <iupdate>
}
    8000395e:	70a2                	ld	ra,40(sp)
    80003960:	7402                	ld	s0,32(sp)
    80003962:	64e2                	ld	s1,24(sp)
    80003964:	6942                	ld	s2,16(sp)
    80003966:	69a2                	ld	s3,8(sp)
    80003968:	6a02                	ld	s4,0(sp)
    8000396a:	6145                	addi	sp,sp,48
    8000396c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000396e:	0009a503          	lw	a0,0(s3)
    80003972:	fffff097          	auipc	ra,0xfffff
    80003976:	67a080e7          	jalr	1658(ra) # 80002fec <bread>
    8000397a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000397c:	05850493          	addi	s1,a0,88
    80003980:	45850913          	addi	s2,a0,1112
    80003984:	a021                	j	8000398c <itrunc+0x7a>
    80003986:	0491                	addi	s1,s1,4
    80003988:	01248b63          	beq	s1,s2,8000399e <itrunc+0x8c>
      if(a[j])
    8000398c:	408c                	lw	a1,0(s1)
    8000398e:	dde5                	beqz	a1,80003986 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003990:	0009a503          	lw	a0,0(s3)
    80003994:	00000097          	auipc	ra,0x0
    80003998:	89e080e7          	jalr	-1890(ra) # 80003232 <bfree>
    8000399c:	b7ed                	j	80003986 <itrunc+0x74>
    brelse(bp);
    8000399e:	8552                	mv	a0,s4
    800039a0:	fffff097          	auipc	ra,0xfffff
    800039a4:	77c080e7          	jalr	1916(ra) # 8000311c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800039a8:	0809a583          	lw	a1,128(s3)
    800039ac:	0009a503          	lw	a0,0(s3)
    800039b0:	00000097          	auipc	ra,0x0
    800039b4:	882080e7          	jalr	-1918(ra) # 80003232 <bfree>
    ip->addrs[NDIRECT] = 0;
    800039b8:	0809a023          	sw	zero,128(s3)
    800039bc:	bf51                	j	80003950 <itrunc+0x3e>

00000000800039be <iput>:
{
    800039be:	1101                	addi	sp,sp,-32
    800039c0:	ec06                	sd	ra,24(sp)
    800039c2:	e822                	sd	s0,16(sp)
    800039c4:	e426                	sd	s1,8(sp)
    800039c6:	e04a                	sd	s2,0(sp)
    800039c8:	1000                	addi	s0,sp,32
    800039ca:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800039cc:	0001c517          	auipc	a0,0x1c
    800039d0:	95c50513          	addi	a0,a0,-1700 # 8001f328 <itable>
    800039d4:	ffffd097          	auipc	ra,0xffffd
    800039d8:	202080e7          	jalr	514(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039dc:	4498                	lw	a4,8(s1)
    800039de:	4785                	li	a5,1
    800039e0:	02f70363          	beq	a4,a5,80003a06 <iput+0x48>
  ip->ref--;
    800039e4:	449c                	lw	a5,8(s1)
    800039e6:	37fd                	addiw	a5,a5,-1
    800039e8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800039ea:	0001c517          	auipc	a0,0x1c
    800039ee:	93e50513          	addi	a0,a0,-1730 # 8001f328 <itable>
    800039f2:	ffffd097          	auipc	ra,0xffffd
    800039f6:	298080e7          	jalr	664(ra) # 80000c8a <release>
}
    800039fa:	60e2                	ld	ra,24(sp)
    800039fc:	6442                	ld	s0,16(sp)
    800039fe:	64a2                	ld	s1,8(sp)
    80003a00:	6902                	ld	s2,0(sp)
    80003a02:	6105                	addi	sp,sp,32
    80003a04:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a06:	40bc                	lw	a5,64(s1)
    80003a08:	dff1                	beqz	a5,800039e4 <iput+0x26>
    80003a0a:	04a49783          	lh	a5,74(s1)
    80003a0e:	fbf9                	bnez	a5,800039e4 <iput+0x26>
    acquiresleep(&ip->lock);
    80003a10:	01048913          	addi	s2,s1,16
    80003a14:	854a                	mv	a0,s2
    80003a16:	00001097          	auipc	ra,0x1
    80003a1a:	aae080e7          	jalr	-1362(ra) # 800044c4 <acquiresleep>
    release(&itable.lock);
    80003a1e:	0001c517          	auipc	a0,0x1c
    80003a22:	90a50513          	addi	a0,a0,-1782 # 8001f328 <itable>
    80003a26:	ffffd097          	auipc	ra,0xffffd
    80003a2a:	264080e7          	jalr	612(ra) # 80000c8a <release>
    itrunc(ip);
    80003a2e:	8526                	mv	a0,s1
    80003a30:	00000097          	auipc	ra,0x0
    80003a34:	ee2080e7          	jalr	-286(ra) # 80003912 <itrunc>
    ip->type = 0;
    80003a38:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a3c:	8526                	mv	a0,s1
    80003a3e:	00000097          	auipc	ra,0x0
    80003a42:	cfa080e7          	jalr	-774(ra) # 80003738 <iupdate>
    ip->valid = 0;
    80003a46:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a4a:	854a                	mv	a0,s2
    80003a4c:	00001097          	auipc	ra,0x1
    80003a50:	ace080e7          	jalr	-1330(ra) # 8000451a <releasesleep>
    acquire(&itable.lock);
    80003a54:	0001c517          	auipc	a0,0x1c
    80003a58:	8d450513          	addi	a0,a0,-1836 # 8001f328 <itable>
    80003a5c:	ffffd097          	auipc	ra,0xffffd
    80003a60:	17a080e7          	jalr	378(ra) # 80000bd6 <acquire>
    80003a64:	b741                	j	800039e4 <iput+0x26>

0000000080003a66 <iunlockput>:
{
    80003a66:	1101                	addi	sp,sp,-32
    80003a68:	ec06                	sd	ra,24(sp)
    80003a6a:	e822                	sd	s0,16(sp)
    80003a6c:	e426                	sd	s1,8(sp)
    80003a6e:	1000                	addi	s0,sp,32
    80003a70:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a72:	00000097          	auipc	ra,0x0
    80003a76:	e54080e7          	jalr	-428(ra) # 800038c6 <iunlock>
  iput(ip);
    80003a7a:	8526                	mv	a0,s1
    80003a7c:	00000097          	auipc	ra,0x0
    80003a80:	f42080e7          	jalr	-190(ra) # 800039be <iput>
}
    80003a84:	60e2                	ld	ra,24(sp)
    80003a86:	6442                	ld	s0,16(sp)
    80003a88:	64a2                	ld	s1,8(sp)
    80003a8a:	6105                	addi	sp,sp,32
    80003a8c:	8082                	ret

0000000080003a8e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a8e:	1141                	addi	sp,sp,-16
    80003a90:	e422                	sd	s0,8(sp)
    80003a92:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a94:	411c                	lw	a5,0(a0)
    80003a96:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a98:	415c                	lw	a5,4(a0)
    80003a9a:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a9c:	04451783          	lh	a5,68(a0)
    80003aa0:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003aa4:	04a51783          	lh	a5,74(a0)
    80003aa8:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003aac:	04c56783          	lwu	a5,76(a0)
    80003ab0:	e99c                	sd	a5,16(a1)
}
    80003ab2:	6422                	ld	s0,8(sp)
    80003ab4:	0141                	addi	sp,sp,16
    80003ab6:	8082                	ret

0000000080003ab8 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ab8:	457c                	lw	a5,76(a0)
    80003aba:	0ed7e963          	bltu	a5,a3,80003bac <readi+0xf4>
{
    80003abe:	7159                	addi	sp,sp,-112
    80003ac0:	f486                	sd	ra,104(sp)
    80003ac2:	f0a2                	sd	s0,96(sp)
    80003ac4:	eca6                	sd	s1,88(sp)
    80003ac6:	e8ca                	sd	s2,80(sp)
    80003ac8:	e4ce                	sd	s3,72(sp)
    80003aca:	e0d2                	sd	s4,64(sp)
    80003acc:	fc56                	sd	s5,56(sp)
    80003ace:	f85a                	sd	s6,48(sp)
    80003ad0:	f45e                	sd	s7,40(sp)
    80003ad2:	f062                	sd	s8,32(sp)
    80003ad4:	ec66                	sd	s9,24(sp)
    80003ad6:	e86a                	sd	s10,16(sp)
    80003ad8:	e46e                	sd	s11,8(sp)
    80003ada:	1880                	addi	s0,sp,112
    80003adc:	8b2a                	mv	s6,a0
    80003ade:	8bae                	mv	s7,a1
    80003ae0:	8a32                	mv	s4,a2
    80003ae2:	84b6                	mv	s1,a3
    80003ae4:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003ae6:	9f35                	addw	a4,a4,a3
    return 0;
    80003ae8:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003aea:	0ad76063          	bltu	a4,a3,80003b8a <readi+0xd2>
  if(off + n > ip->size)
    80003aee:	00e7f463          	bgeu	a5,a4,80003af6 <readi+0x3e>
    n = ip->size - off;
    80003af2:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003af6:	0a0a8963          	beqz	s5,80003ba8 <readi+0xf0>
    80003afa:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003afc:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003b00:	5c7d                	li	s8,-1
    80003b02:	a82d                	j	80003b3c <readi+0x84>
    80003b04:	020d1d93          	slli	s11,s10,0x20
    80003b08:	020ddd93          	srli	s11,s11,0x20
    80003b0c:	05890613          	addi	a2,s2,88
    80003b10:	86ee                	mv	a3,s11
    80003b12:	963a                	add	a2,a2,a4
    80003b14:	85d2                	mv	a1,s4
    80003b16:	855e                	mv	a0,s7
    80003b18:	fffff097          	auipc	ra,0xfffff
    80003b1c:	956080e7          	jalr	-1706(ra) # 8000246e <either_copyout>
    80003b20:	05850d63          	beq	a0,s8,80003b7a <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003b24:	854a                	mv	a0,s2
    80003b26:	fffff097          	auipc	ra,0xfffff
    80003b2a:	5f6080e7          	jalr	1526(ra) # 8000311c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b2e:	013d09bb          	addw	s3,s10,s3
    80003b32:	009d04bb          	addw	s1,s10,s1
    80003b36:	9a6e                	add	s4,s4,s11
    80003b38:	0559f763          	bgeu	s3,s5,80003b86 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003b3c:	00a4d59b          	srliw	a1,s1,0xa
    80003b40:	855a                	mv	a0,s6
    80003b42:	00000097          	auipc	ra,0x0
    80003b46:	89e080e7          	jalr	-1890(ra) # 800033e0 <bmap>
    80003b4a:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003b4e:	cd85                	beqz	a1,80003b86 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003b50:	000b2503          	lw	a0,0(s6)
    80003b54:	fffff097          	auipc	ra,0xfffff
    80003b58:	498080e7          	jalr	1176(ra) # 80002fec <bread>
    80003b5c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b5e:	3ff4f713          	andi	a4,s1,1023
    80003b62:	40ec87bb          	subw	a5,s9,a4
    80003b66:	413a86bb          	subw	a3,s5,s3
    80003b6a:	8d3e                	mv	s10,a5
    80003b6c:	2781                	sext.w	a5,a5
    80003b6e:	0006861b          	sext.w	a2,a3
    80003b72:	f8f679e3          	bgeu	a2,a5,80003b04 <readi+0x4c>
    80003b76:	8d36                	mv	s10,a3
    80003b78:	b771                	j	80003b04 <readi+0x4c>
      brelse(bp);
    80003b7a:	854a                	mv	a0,s2
    80003b7c:	fffff097          	auipc	ra,0xfffff
    80003b80:	5a0080e7          	jalr	1440(ra) # 8000311c <brelse>
      tot = -1;
    80003b84:	59fd                	li	s3,-1
  }
  return tot;
    80003b86:	0009851b          	sext.w	a0,s3
}
    80003b8a:	70a6                	ld	ra,104(sp)
    80003b8c:	7406                	ld	s0,96(sp)
    80003b8e:	64e6                	ld	s1,88(sp)
    80003b90:	6946                	ld	s2,80(sp)
    80003b92:	69a6                	ld	s3,72(sp)
    80003b94:	6a06                	ld	s4,64(sp)
    80003b96:	7ae2                	ld	s5,56(sp)
    80003b98:	7b42                	ld	s6,48(sp)
    80003b9a:	7ba2                	ld	s7,40(sp)
    80003b9c:	7c02                	ld	s8,32(sp)
    80003b9e:	6ce2                	ld	s9,24(sp)
    80003ba0:	6d42                	ld	s10,16(sp)
    80003ba2:	6da2                	ld	s11,8(sp)
    80003ba4:	6165                	addi	sp,sp,112
    80003ba6:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ba8:	89d6                	mv	s3,s5
    80003baa:	bff1                	j	80003b86 <readi+0xce>
    return 0;
    80003bac:	4501                	li	a0,0
}
    80003bae:	8082                	ret

0000000080003bb0 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003bb0:	457c                	lw	a5,76(a0)
    80003bb2:	10d7e863          	bltu	a5,a3,80003cc2 <writei+0x112>
{
    80003bb6:	7159                	addi	sp,sp,-112
    80003bb8:	f486                	sd	ra,104(sp)
    80003bba:	f0a2                	sd	s0,96(sp)
    80003bbc:	eca6                	sd	s1,88(sp)
    80003bbe:	e8ca                	sd	s2,80(sp)
    80003bc0:	e4ce                	sd	s3,72(sp)
    80003bc2:	e0d2                	sd	s4,64(sp)
    80003bc4:	fc56                	sd	s5,56(sp)
    80003bc6:	f85a                	sd	s6,48(sp)
    80003bc8:	f45e                	sd	s7,40(sp)
    80003bca:	f062                	sd	s8,32(sp)
    80003bcc:	ec66                	sd	s9,24(sp)
    80003bce:	e86a                	sd	s10,16(sp)
    80003bd0:	e46e                	sd	s11,8(sp)
    80003bd2:	1880                	addi	s0,sp,112
    80003bd4:	8aaa                	mv	s5,a0
    80003bd6:	8bae                	mv	s7,a1
    80003bd8:	8a32                	mv	s4,a2
    80003bda:	8936                	mv	s2,a3
    80003bdc:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003bde:	00e687bb          	addw	a5,a3,a4
    80003be2:	0ed7e263          	bltu	a5,a3,80003cc6 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003be6:	00043737          	lui	a4,0x43
    80003bea:	0ef76063          	bltu	a4,a5,80003cca <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bee:	0c0b0863          	beqz	s6,80003cbe <writei+0x10e>
    80003bf2:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bf4:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003bf8:	5c7d                	li	s8,-1
    80003bfa:	a091                	j	80003c3e <writei+0x8e>
    80003bfc:	020d1d93          	slli	s11,s10,0x20
    80003c00:	020ddd93          	srli	s11,s11,0x20
    80003c04:	05848513          	addi	a0,s1,88
    80003c08:	86ee                	mv	a3,s11
    80003c0a:	8652                	mv	a2,s4
    80003c0c:	85de                	mv	a1,s7
    80003c0e:	953a                	add	a0,a0,a4
    80003c10:	fffff097          	auipc	ra,0xfffff
    80003c14:	8b4080e7          	jalr	-1868(ra) # 800024c4 <either_copyin>
    80003c18:	07850263          	beq	a0,s8,80003c7c <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003c1c:	8526                	mv	a0,s1
    80003c1e:	00000097          	auipc	ra,0x0
    80003c22:	788080e7          	jalr	1928(ra) # 800043a6 <log_write>
    brelse(bp);
    80003c26:	8526                	mv	a0,s1
    80003c28:	fffff097          	auipc	ra,0xfffff
    80003c2c:	4f4080e7          	jalr	1268(ra) # 8000311c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c30:	013d09bb          	addw	s3,s10,s3
    80003c34:	012d093b          	addw	s2,s10,s2
    80003c38:	9a6e                	add	s4,s4,s11
    80003c3a:	0569f663          	bgeu	s3,s6,80003c86 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003c3e:	00a9559b          	srliw	a1,s2,0xa
    80003c42:	8556                	mv	a0,s5
    80003c44:	fffff097          	auipc	ra,0xfffff
    80003c48:	79c080e7          	jalr	1948(ra) # 800033e0 <bmap>
    80003c4c:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003c50:	c99d                	beqz	a1,80003c86 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003c52:	000aa503          	lw	a0,0(s5)
    80003c56:	fffff097          	auipc	ra,0xfffff
    80003c5a:	396080e7          	jalr	918(ra) # 80002fec <bread>
    80003c5e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c60:	3ff97713          	andi	a4,s2,1023
    80003c64:	40ec87bb          	subw	a5,s9,a4
    80003c68:	413b06bb          	subw	a3,s6,s3
    80003c6c:	8d3e                	mv	s10,a5
    80003c6e:	2781                	sext.w	a5,a5
    80003c70:	0006861b          	sext.w	a2,a3
    80003c74:	f8f674e3          	bgeu	a2,a5,80003bfc <writei+0x4c>
    80003c78:	8d36                	mv	s10,a3
    80003c7a:	b749                	j	80003bfc <writei+0x4c>
      brelse(bp);
    80003c7c:	8526                	mv	a0,s1
    80003c7e:	fffff097          	auipc	ra,0xfffff
    80003c82:	49e080e7          	jalr	1182(ra) # 8000311c <brelse>
  }

  if(off > ip->size)
    80003c86:	04caa783          	lw	a5,76(s5)
    80003c8a:	0127f463          	bgeu	a5,s2,80003c92 <writei+0xe2>
    ip->size = off;
    80003c8e:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003c92:	8556                	mv	a0,s5
    80003c94:	00000097          	auipc	ra,0x0
    80003c98:	aa4080e7          	jalr	-1372(ra) # 80003738 <iupdate>

  return tot;
    80003c9c:	0009851b          	sext.w	a0,s3
}
    80003ca0:	70a6                	ld	ra,104(sp)
    80003ca2:	7406                	ld	s0,96(sp)
    80003ca4:	64e6                	ld	s1,88(sp)
    80003ca6:	6946                	ld	s2,80(sp)
    80003ca8:	69a6                	ld	s3,72(sp)
    80003caa:	6a06                	ld	s4,64(sp)
    80003cac:	7ae2                	ld	s5,56(sp)
    80003cae:	7b42                	ld	s6,48(sp)
    80003cb0:	7ba2                	ld	s7,40(sp)
    80003cb2:	7c02                	ld	s8,32(sp)
    80003cb4:	6ce2                	ld	s9,24(sp)
    80003cb6:	6d42                	ld	s10,16(sp)
    80003cb8:	6da2                	ld	s11,8(sp)
    80003cba:	6165                	addi	sp,sp,112
    80003cbc:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cbe:	89da                	mv	s3,s6
    80003cc0:	bfc9                	j	80003c92 <writei+0xe2>
    return -1;
    80003cc2:	557d                	li	a0,-1
}
    80003cc4:	8082                	ret
    return -1;
    80003cc6:	557d                	li	a0,-1
    80003cc8:	bfe1                	j	80003ca0 <writei+0xf0>
    return -1;
    80003cca:	557d                	li	a0,-1
    80003ccc:	bfd1                	j	80003ca0 <writei+0xf0>

0000000080003cce <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003cce:	1141                	addi	sp,sp,-16
    80003cd0:	e406                	sd	ra,8(sp)
    80003cd2:	e022                	sd	s0,0(sp)
    80003cd4:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003cd6:	4639                	li	a2,14
    80003cd8:	ffffd097          	auipc	ra,0xffffd
    80003cdc:	0ca080e7          	jalr	202(ra) # 80000da2 <strncmp>
}
    80003ce0:	60a2                	ld	ra,8(sp)
    80003ce2:	6402                	ld	s0,0(sp)
    80003ce4:	0141                	addi	sp,sp,16
    80003ce6:	8082                	ret

0000000080003ce8 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003ce8:	7139                	addi	sp,sp,-64
    80003cea:	fc06                	sd	ra,56(sp)
    80003cec:	f822                	sd	s0,48(sp)
    80003cee:	f426                	sd	s1,40(sp)
    80003cf0:	f04a                	sd	s2,32(sp)
    80003cf2:	ec4e                	sd	s3,24(sp)
    80003cf4:	e852                	sd	s4,16(sp)
    80003cf6:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003cf8:	04451703          	lh	a4,68(a0)
    80003cfc:	4785                	li	a5,1
    80003cfe:	00f71a63          	bne	a4,a5,80003d12 <dirlookup+0x2a>
    80003d02:	892a                	mv	s2,a0
    80003d04:	89ae                	mv	s3,a1
    80003d06:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d08:	457c                	lw	a5,76(a0)
    80003d0a:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003d0c:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d0e:	e79d                	bnez	a5,80003d3c <dirlookup+0x54>
    80003d10:	a8a5                	j	80003d88 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003d12:	00005517          	auipc	a0,0x5
    80003d16:	98650513          	addi	a0,a0,-1658 # 80008698 <syscalls+0x1b0>
    80003d1a:	ffffd097          	auipc	ra,0xffffd
    80003d1e:	826080e7          	jalr	-2010(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003d22:	00005517          	auipc	a0,0x5
    80003d26:	98e50513          	addi	a0,a0,-1650 # 800086b0 <syscalls+0x1c8>
    80003d2a:	ffffd097          	auipc	ra,0xffffd
    80003d2e:	816080e7          	jalr	-2026(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d32:	24c1                	addiw	s1,s1,16
    80003d34:	04c92783          	lw	a5,76(s2)
    80003d38:	04f4f763          	bgeu	s1,a5,80003d86 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d3c:	4741                	li	a4,16
    80003d3e:	86a6                	mv	a3,s1
    80003d40:	fc040613          	addi	a2,s0,-64
    80003d44:	4581                	li	a1,0
    80003d46:	854a                	mv	a0,s2
    80003d48:	00000097          	auipc	ra,0x0
    80003d4c:	d70080e7          	jalr	-656(ra) # 80003ab8 <readi>
    80003d50:	47c1                	li	a5,16
    80003d52:	fcf518e3          	bne	a0,a5,80003d22 <dirlookup+0x3a>
    if(de.inum == 0)
    80003d56:	fc045783          	lhu	a5,-64(s0)
    80003d5a:	dfe1                	beqz	a5,80003d32 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d5c:	fc240593          	addi	a1,s0,-62
    80003d60:	854e                	mv	a0,s3
    80003d62:	00000097          	auipc	ra,0x0
    80003d66:	f6c080e7          	jalr	-148(ra) # 80003cce <namecmp>
    80003d6a:	f561                	bnez	a0,80003d32 <dirlookup+0x4a>
      if(poff)
    80003d6c:	000a0463          	beqz	s4,80003d74 <dirlookup+0x8c>
        *poff = off;
    80003d70:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d74:	fc045583          	lhu	a1,-64(s0)
    80003d78:	00092503          	lw	a0,0(s2)
    80003d7c:	fffff097          	auipc	ra,0xfffff
    80003d80:	74e080e7          	jalr	1870(ra) # 800034ca <iget>
    80003d84:	a011                	j	80003d88 <dirlookup+0xa0>
  return 0;
    80003d86:	4501                	li	a0,0
}
    80003d88:	70e2                	ld	ra,56(sp)
    80003d8a:	7442                	ld	s0,48(sp)
    80003d8c:	74a2                	ld	s1,40(sp)
    80003d8e:	7902                	ld	s2,32(sp)
    80003d90:	69e2                	ld	s3,24(sp)
    80003d92:	6a42                	ld	s4,16(sp)
    80003d94:	6121                	addi	sp,sp,64
    80003d96:	8082                	ret

0000000080003d98 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d98:	711d                	addi	sp,sp,-96
    80003d9a:	ec86                	sd	ra,88(sp)
    80003d9c:	e8a2                	sd	s0,80(sp)
    80003d9e:	e4a6                	sd	s1,72(sp)
    80003da0:	e0ca                	sd	s2,64(sp)
    80003da2:	fc4e                	sd	s3,56(sp)
    80003da4:	f852                	sd	s4,48(sp)
    80003da6:	f456                	sd	s5,40(sp)
    80003da8:	f05a                	sd	s6,32(sp)
    80003daa:	ec5e                	sd	s7,24(sp)
    80003dac:	e862                	sd	s8,16(sp)
    80003dae:	e466                	sd	s9,8(sp)
    80003db0:	e06a                	sd	s10,0(sp)
    80003db2:	1080                	addi	s0,sp,96
    80003db4:	84aa                	mv	s1,a0
    80003db6:	8b2e                	mv	s6,a1
    80003db8:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003dba:	00054703          	lbu	a4,0(a0)
    80003dbe:	02f00793          	li	a5,47
    80003dc2:	02f70363          	beq	a4,a5,80003de8 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003dc6:	ffffe097          	auipc	ra,0xffffe
    80003dca:	be6080e7          	jalr	-1050(ra) # 800019ac <myproc>
    80003dce:	15053503          	ld	a0,336(a0)
    80003dd2:	00000097          	auipc	ra,0x0
    80003dd6:	9f4080e7          	jalr	-1548(ra) # 800037c6 <idup>
    80003dda:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003ddc:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003de0:	4cb5                	li	s9,13
  len = path - s;
    80003de2:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003de4:	4c05                	li	s8,1
    80003de6:	a87d                	j	80003ea4 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003de8:	4585                	li	a1,1
    80003dea:	4505                	li	a0,1
    80003dec:	fffff097          	auipc	ra,0xfffff
    80003df0:	6de080e7          	jalr	1758(ra) # 800034ca <iget>
    80003df4:	8a2a                	mv	s4,a0
    80003df6:	b7dd                	j	80003ddc <namex+0x44>
      iunlockput(ip);
    80003df8:	8552                	mv	a0,s4
    80003dfa:	00000097          	auipc	ra,0x0
    80003dfe:	c6c080e7          	jalr	-916(ra) # 80003a66 <iunlockput>
      return 0;
    80003e02:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003e04:	8552                	mv	a0,s4
    80003e06:	60e6                	ld	ra,88(sp)
    80003e08:	6446                	ld	s0,80(sp)
    80003e0a:	64a6                	ld	s1,72(sp)
    80003e0c:	6906                	ld	s2,64(sp)
    80003e0e:	79e2                	ld	s3,56(sp)
    80003e10:	7a42                	ld	s4,48(sp)
    80003e12:	7aa2                	ld	s5,40(sp)
    80003e14:	7b02                	ld	s6,32(sp)
    80003e16:	6be2                	ld	s7,24(sp)
    80003e18:	6c42                	ld	s8,16(sp)
    80003e1a:	6ca2                	ld	s9,8(sp)
    80003e1c:	6d02                	ld	s10,0(sp)
    80003e1e:	6125                	addi	sp,sp,96
    80003e20:	8082                	ret
      iunlock(ip);
    80003e22:	8552                	mv	a0,s4
    80003e24:	00000097          	auipc	ra,0x0
    80003e28:	aa2080e7          	jalr	-1374(ra) # 800038c6 <iunlock>
      return ip;
    80003e2c:	bfe1                	j	80003e04 <namex+0x6c>
      iunlockput(ip);
    80003e2e:	8552                	mv	a0,s4
    80003e30:	00000097          	auipc	ra,0x0
    80003e34:	c36080e7          	jalr	-970(ra) # 80003a66 <iunlockput>
      return 0;
    80003e38:	8a4e                	mv	s4,s3
    80003e3a:	b7e9                	j	80003e04 <namex+0x6c>
  len = path - s;
    80003e3c:	40998633          	sub	a2,s3,s1
    80003e40:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003e44:	09acd863          	bge	s9,s10,80003ed4 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003e48:	4639                	li	a2,14
    80003e4a:	85a6                	mv	a1,s1
    80003e4c:	8556                	mv	a0,s5
    80003e4e:	ffffd097          	auipc	ra,0xffffd
    80003e52:	ee0080e7          	jalr	-288(ra) # 80000d2e <memmove>
    80003e56:	84ce                	mv	s1,s3
  while(*path == '/')
    80003e58:	0004c783          	lbu	a5,0(s1)
    80003e5c:	01279763          	bne	a5,s2,80003e6a <namex+0xd2>
    path++;
    80003e60:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e62:	0004c783          	lbu	a5,0(s1)
    80003e66:	ff278de3          	beq	a5,s2,80003e60 <namex+0xc8>
    ilock(ip);
    80003e6a:	8552                	mv	a0,s4
    80003e6c:	00000097          	auipc	ra,0x0
    80003e70:	998080e7          	jalr	-1640(ra) # 80003804 <ilock>
    if(ip->type != T_DIR){
    80003e74:	044a1783          	lh	a5,68(s4)
    80003e78:	f98790e3          	bne	a5,s8,80003df8 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003e7c:	000b0563          	beqz	s6,80003e86 <namex+0xee>
    80003e80:	0004c783          	lbu	a5,0(s1)
    80003e84:	dfd9                	beqz	a5,80003e22 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e86:	865e                	mv	a2,s7
    80003e88:	85d6                	mv	a1,s5
    80003e8a:	8552                	mv	a0,s4
    80003e8c:	00000097          	auipc	ra,0x0
    80003e90:	e5c080e7          	jalr	-420(ra) # 80003ce8 <dirlookup>
    80003e94:	89aa                	mv	s3,a0
    80003e96:	dd41                	beqz	a0,80003e2e <namex+0x96>
    iunlockput(ip);
    80003e98:	8552                	mv	a0,s4
    80003e9a:	00000097          	auipc	ra,0x0
    80003e9e:	bcc080e7          	jalr	-1076(ra) # 80003a66 <iunlockput>
    ip = next;
    80003ea2:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003ea4:	0004c783          	lbu	a5,0(s1)
    80003ea8:	01279763          	bne	a5,s2,80003eb6 <namex+0x11e>
    path++;
    80003eac:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003eae:	0004c783          	lbu	a5,0(s1)
    80003eb2:	ff278de3          	beq	a5,s2,80003eac <namex+0x114>
  if(*path == 0)
    80003eb6:	cb9d                	beqz	a5,80003eec <namex+0x154>
  while(*path != '/' && *path != 0)
    80003eb8:	0004c783          	lbu	a5,0(s1)
    80003ebc:	89a6                	mv	s3,s1
  len = path - s;
    80003ebe:	8d5e                	mv	s10,s7
    80003ec0:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003ec2:	01278963          	beq	a5,s2,80003ed4 <namex+0x13c>
    80003ec6:	dbbd                	beqz	a5,80003e3c <namex+0xa4>
    path++;
    80003ec8:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003eca:	0009c783          	lbu	a5,0(s3)
    80003ece:	ff279ce3          	bne	a5,s2,80003ec6 <namex+0x12e>
    80003ed2:	b7ad                	j	80003e3c <namex+0xa4>
    memmove(name, s, len);
    80003ed4:	2601                	sext.w	a2,a2
    80003ed6:	85a6                	mv	a1,s1
    80003ed8:	8556                	mv	a0,s5
    80003eda:	ffffd097          	auipc	ra,0xffffd
    80003ede:	e54080e7          	jalr	-428(ra) # 80000d2e <memmove>
    name[len] = 0;
    80003ee2:	9d56                	add	s10,s10,s5
    80003ee4:	000d0023          	sb	zero,0(s10)
    80003ee8:	84ce                	mv	s1,s3
    80003eea:	b7bd                	j	80003e58 <namex+0xc0>
  if(nameiparent){
    80003eec:	f00b0ce3          	beqz	s6,80003e04 <namex+0x6c>
    iput(ip);
    80003ef0:	8552                	mv	a0,s4
    80003ef2:	00000097          	auipc	ra,0x0
    80003ef6:	acc080e7          	jalr	-1332(ra) # 800039be <iput>
    return 0;
    80003efa:	4a01                	li	s4,0
    80003efc:	b721                	j	80003e04 <namex+0x6c>

0000000080003efe <dirlink>:
{
    80003efe:	7139                	addi	sp,sp,-64
    80003f00:	fc06                	sd	ra,56(sp)
    80003f02:	f822                	sd	s0,48(sp)
    80003f04:	f426                	sd	s1,40(sp)
    80003f06:	f04a                	sd	s2,32(sp)
    80003f08:	ec4e                	sd	s3,24(sp)
    80003f0a:	e852                	sd	s4,16(sp)
    80003f0c:	0080                	addi	s0,sp,64
    80003f0e:	892a                	mv	s2,a0
    80003f10:	8a2e                	mv	s4,a1
    80003f12:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003f14:	4601                	li	a2,0
    80003f16:	00000097          	auipc	ra,0x0
    80003f1a:	dd2080e7          	jalr	-558(ra) # 80003ce8 <dirlookup>
    80003f1e:	e93d                	bnez	a0,80003f94 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f20:	04c92483          	lw	s1,76(s2)
    80003f24:	c49d                	beqz	s1,80003f52 <dirlink+0x54>
    80003f26:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f28:	4741                	li	a4,16
    80003f2a:	86a6                	mv	a3,s1
    80003f2c:	fc040613          	addi	a2,s0,-64
    80003f30:	4581                	li	a1,0
    80003f32:	854a                	mv	a0,s2
    80003f34:	00000097          	auipc	ra,0x0
    80003f38:	b84080e7          	jalr	-1148(ra) # 80003ab8 <readi>
    80003f3c:	47c1                	li	a5,16
    80003f3e:	06f51163          	bne	a0,a5,80003fa0 <dirlink+0xa2>
    if(de.inum == 0)
    80003f42:	fc045783          	lhu	a5,-64(s0)
    80003f46:	c791                	beqz	a5,80003f52 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f48:	24c1                	addiw	s1,s1,16
    80003f4a:	04c92783          	lw	a5,76(s2)
    80003f4e:	fcf4ede3          	bltu	s1,a5,80003f28 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f52:	4639                	li	a2,14
    80003f54:	85d2                	mv	a1,s4
    80003f56:	fc240513          	addi	a0,s0,-62
    80003f5a:	ffffd097          	auipc	ra,0xffffd
    80003f5e:	e84080e7          	jalr	-380(ra) # 80000dde <strncpy>
  de.inum = inum;
    80003f62:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f66:	4741                	li	a4,16
    80003f68:	86a6                	mv	a3,s1
    80003f6a:	fc040613          	addi	a2,s0,-64
    80003f6e:	4581                	li	a1,0
    80003f70:	854a                	mv	a0,s2
    80003f72:	00000097          	auipc	ra,0x0
    80003f76:	c3e080e7          	jalr	-962(ra) # 80003bb0 <writei>
    80003f7a:	1541                	addi	a0,a0,-16
    80003f7c:	00a03533          	snez	a0,a0
    80003f80:	40a00533          	neg	a0,a0
}
    80003f84:	70e2                	ld	ra,56(sp)
    80003f86:	7442                	ld	s0,48(sp)
    80003f88:	74a2                	ld	s1,40(sp)
    80003f8a:	7902                	ld	s2,32(sp)
    80003f8c:	69e2                	ld	s3,24(sp)
    80003f8e:	6a42                	ld	s4,16(sp)
    80003f90:	6121                	addi	sp,sp,64
    80003f92:	8082                	ret
    iput(ip);
    80003f94:	00000097          	auipc	ra,0x0
    80003f98:	a2a080e7          	jalr	-1494(ra) # 800039be <iput>
    return -1;
    80003f9c:	557d                	li	a0,-1
    80003f9e:	b7dd                	j	80003f84 <dirlink+0x86>
      panic("dirlink read");
    80003fa0:	00004517          	auipc	a0,0x4
    80003fa4:	72050513          	addi	a0,a0,1824 # 800086c0 <syscalls+0x1d8>
    80003fa8:	ffffc097          	auipc	ra,0xffffc
    80003fac:	598080e7          	jalr	1432(ra) # 80000540 <panic>

0000000080003fb0 <namei>:

struct inode*
namei(char *path)
{
    80003fb0:	1101                	addi	sp,sp,-32
    80003fb2:	ec06                	sd	ra,24(sp)
    80003fb4:	e822                	sd	s0,16(sp)
    80003fb6:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003fb8:	fe040613          	addi	a2,s0,-32
    80003fbc:	4581                	li	a1,0
    80003fbe:	00000097          	auipc	ra,0x0
    80003fc2:	dda080e7          	jalr	-550(ra) # 80003d98 <namex>
}
    80003fc6:	60e2                	ld	ra,24(sp)
    80003fc8:	6442                	ld	s0,16(sp)
    80003fca:	6105                	addi	sp,sp,32
    80003fcc:	8082                	ret

0000000080003fce <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003fce:	1141                	addi	sp,sp,-16
    80003fd0:	e406                	sd	ra,8(sp)
    80003fd2:	e022                	sd	s0,0(sp)
    80003fd4:	0800                	addi	s0,sp,16
    80003fd6:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003fd8:	4585                	li	a1,1
    80003fda:	00000097          	auipc	ra,0x0
    80003fde:	dbe080e7          	jalr	-578(ra) # 80003d98 <namex>
}
    80003fe2:	60a2                	ld	ra,8(sp)
    80003fe4:	6402                	ld	s0,0(sp)
    80003fe6:	0141                	addi	sp,sp,16
    80003fe8:	8082                	ret

0000000080003fea <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003fea:	1101                	addi	sp,sp,-32
    80003fec:	ec06                	sd	ra,24(sp)
    80003fee:	e822                	sd	s0,16(sp)
    80003ff0:	e426                	sd	s1,8(sp)
    80003ff2:	e04a                	sd	s2,0(sp)
    80003ff4:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003ff6:	0001d917          	auipc	s2,0x1d
    80003ffa:	dda90913          	addi	s2,s2,-550 # 80020dd0 <log>
    80003ffe:	01892583          	lw	a1,24(s2)
    80004002:	02892503          	lw	a0,40(s2)
    80004006:	fffff097          	auipc	ra,0xfffff
    8000400a:	fe6080e7          	jalr	-26(ra) # 80002fec <bread>
    8000400e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004010:	02c92683          	lw	a3,44(s2)
    80004014:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004016:	02d05863          	blez	a3,80004046 <write_head+0x5c>
    8000401a:	0001d797          	auipc	a5,0x1d
    8000401e:	de678793          	addi	a5,a5,-538 # 80020e00 <log+0x30>
    80004022:	05c50713          	addi	a4,a0,92
    80004026:	36fd                	addiw	a3,a3,-1
    80004028:	02069613          	slli	a2,a3,0x20
    8000402c:	01e65693          	srli	a3,a2,0x1e
    80004030:	0001d617          	auipc	a2,0x1d
    80004034:	dd460613          	addi	a2,a2,-556 # 80020e04 <log+0x34>
    80004038:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000403a:	4390                	lw	a2,0(a5)
    8000403c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000403e:	0791                	addi	a5,a5,4
    80004040:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80004042:	fed79ce3          	bne	a5,a3,8000403a <write_head+0x50>
  }
  bwrite(buf);
    80004046:	8526                	mv	a0,s1
    80004048:	fffff097          	auipc	ra,0xfffff
    8000404c:	096080e7          	jalr	150(ra) # 800030de <bwrite>
  brelse(buf);
    80004050:	8526                	mv	a0,s1
    80004052:	fffff097          	auipc	ra,0xfffff
    80004056:	0ca080e7          	jalr	202(ra) # 8000311c <brelse>
}
    8000405a:	60e2                	ld	ra,24(sp)
    8000405c:	6442                	ld	s0,16(sp)
    8000405e:	64a2                	ld	s1,8(sp)
    80004060:	6902                	ld	s2,0(sp)
    80004062:	6105                	addi	sp,sp,32
    80004064:	8082                	ret

0000000080004066 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004066:	0001d797          	auipc	a5,0x1d
    8000406a:	d967a783          	lw	a5,-618(a5) # 80020dfc <log+0x2c>
    8000406e:	0af05d63          	blez	a5,80004128 <install_trans+0xc2>
{
    80004072:	7139                	addi	sp,sp,-64
    80004074:	fc06                	sd	ra,56(sp)
    80004076:	f822                	sd	s0,48(sp)
    80004078:	f426                	sd	s1,40(sp)
    8000407a:	f04a                	sd	s2,32(sp)
    8000407c:	ec4e                	sd	s3,24(sp)
    8000407e:	e852                	sd	s4,16(sp)
    80004080:	e456                	sd	s5,8(sp)
    80004082:	e05a                	sd	s6,0(sp)
    80004084:	0080                	addi	s0,sp,64
    80004086:	8b2a                	mv	s6,a0
    80004088:	0001da97          	auipc	s5,0x1d
    8000408c:	d78a8a93          	addi	s5,s5,-648 # 80020e00 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004090:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004092:	0001d997          	auipc	s3,0x1d
    80004096:	d3e98993          	addi	s3,s3,-706 # 80020dd0 <log>
    8000409a:	a00d                	j	800040bc <install_trans+0x56>
    brelse(lbuf);
    8000409c:	854a                	mv	a0,s2
    8000409e:	fffff097          	auipc	ra,0xfffff
    800040a2:	07e080e7          	jalr	126(ra) # 8000311c <brelse>
    brelse(dbuf);
    800040a6:	8526                	mv	a0,s1
    800040a8:	fffff097          	auipc	ra,0xfffff
    800040ac:	074080e7          	jalr	116(ra) # 8000311c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040b0:	2a05                	addiw	s4,s4,1
    800040b2:	0a91                	addi	s5,s5,4
    800040b4:	02c9a783          	lw	a5,44(s3)
    800040b8:	04fa5e63          	bge	s4,a5,80004114 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040bc:	0189a583          	lw	a1,24(s3)
    800040c0:	014585bb          	addw	a1,a1,s4
    800040c4:	2585                	addiw	a1,a1,1
    800040c6:	0289a503          	lw	a0,40(s3)
    800040ca:	fffff097          	auipc	ra,0xfffff
    800040ce:	f22080e7          	jalr	-222(ra) # 80002fec <bread>
    800040d2:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800040d4:	000aa583          	lw	a1,0(s5)
    800040d8:	0289a503          	lw	a0,40(s3)
    800040dc:	fffff097          	auipc	ra,0xfffff
    800040e0:	f10080e7          	jalr	-240(ra) # 80002fec <bread>
    800040e4:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800040e6:	40000613          	li	a2,1024
    800040ea:	05890593          	addi	a1,s2,88
    800040ee:	05850513          	addi	a0,a0,88
    800040f2:	ffffd097          	auipc	ra,0xffffd
    800040f6:	c3c080e7          	jalr	-964(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    800040fa:	8526                	mv	a0,s1
    800040fc:	fffff097          	auipc	ra,0xfffff
    80004100:	fe2080e7          	jalr	-30(ra) # 800030de <bwrite>
    if(recovering == 0)
    80004104:	f80b1ce3          	bnez	s6,8000409c <install_trans+0x36>
      bunpin(dbuf);
    80004108:	8526                	mv	a0,s1
    8000410a:	fffff097          	auipc	ra,0xfffff
    8000410e:	0ec080e7          	jalr	236(ra) # 800031f6 <bunpin>
    80004112:	b769                	j	8000409c <install_trans+0x36>
}
    80004114:	70e2                	ld	ra,56(sp)
    80004116:	7442                	ld	s0,48(sp)
    80004118:	74a2                	ld	s1,40(sp)
    8000411a:	7902                	ld	s2,32(sp)
    8000411c:	69e2                	ld	s3,24(sp)
    8000411e:	6a42                	ld	s4,16(sp)
    80004120:	6aa2                	ld	s5,8(sp)
    80004122:	6b02                	ld	s6,0(sp)
    80004124:	6121                	addi	sp,sp,64
    80004126:	8082                	ret
    80004128:	8082                	ret

000000008000412a <initlog>:
{
    8000412a:	7179                	addi	sp,sp,-48
    8000412c:	f406                	sd	ra,40(sp)
    8000412e:	f022                	sd	s0,32(sp)
    80004130:	ec26                	sd	s1,24(sp)
    80004132:	e84a                	sd	s2,16(sp)
    80004134:	e44e                	sd	s3,8(sp)
    80004136:	1800                	addi	s0,sp,48
    80004138:	892a                	mv	s2,a0
    8000413a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000413c:	0001d497          	auipc	s1,0x1d
    80004140:	c9448493          	addi	s1,s1,-876 # 80020dd0 <log>
    80004144:	00004597          	auipc	a1,0x4
    80004148:	58c58593          	addi	a1,a1,1420 # 800086d0 <syscalls+0x1e8>
    8000414c:	8526                	mv	a0,s1
    8000414e:	ffffd097          	auipc	ra,0xffffd
    80004152:	9f8080e7          	jalr	-1544(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80004156:	0149a583          	lw	a1,20(s3)
    8000415a:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000415c:	0109a783          	lw	a5,16(s3)
    80004160:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004162:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004166:	854a                	mv	a0,s2
    80004168:	fffff097          	auipc	ra,0xfffff
    8000416c:	e84080e7          	jalr	-380(ra) # 80002fec <bread>
  log.lh.n = lh->n;
    80004170:	4d34                	lw	a3,88(a0)
    80004172:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004174:	02d05663          	blez	a3,800041a0 <initlog+0x76>
    80004178:	05c50793          	addi	a5,a0,92
    8000417c:	0001d717          	auipc	a4,0x1d
    80004180:	c8470713          	addi	a4,a4,-892 # 80020e00 <log+0x30>
    80004184:	36fd                	addiw	a3,a3,-1
    80004186:	02069613          	slli	a2,a3,0x20
    8000418a:	01e65693          	srli	a3,a2,0x1e
    8000418e:	06050613          	addi	a2,a0,96
    80004192:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004194:	4390                	lw	a2,0(a5)
    80004196:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004198:	0791                	addi	a5,a5,4
    8000419a:	0711                	addi	a4,a4,4
    8000419c:	fed79ce3          	bne	a5,a3,80004194 <initlog+0x6a>
  brelse(buf);
    800041a0:	fffff097          	auipc	ra,0xfffff
    800041a4:	f7c080e7          	jalr	-132(ra) # 8000311c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800041a8:	4505                	li	a0,1
    800041aa:	00000097          	auipc	ra,0x0
    800041ae:	ebc080e7          	jalr	-324(ra) # 80004066 <install_trans>
  log.lh.n = 0;
    800041b2:	0001d797          	auipc	a5,0x1d
    800041b6:	c407a523          	sw	zero,-950(a5) # 80020dfc <log+0x2c>
  write_head(); // clear the log
    800041ba:	00000097          	auipc	ra,0x0
    800041be:	e30080e7          	jalr	-464(ra) # 80003fea <write_head>
}
    800041c2:	70a2                	ld	ra,40(sp)
    800041c4:	7402                	ld	s0,32(sp)
    800041c6:	64e2                	ld	s1,24(sp)
    800041c8:	6942                	ld	s2,16(sp)
    800041ca:	69a2                	ld	s3,8(sp)
    800041cc:	6145                	addi	sp,sp,48
    800041ce:	8082                	ret

00000000800041d0 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800041d0:	1101                	addi	sp,sp,-32
    800041d2:	ec06                	sd	ra,24(sp)
    800041d4:	e822                	sd	s0,16(sp)
    800041d6:	e426                	sd	s1,8(sp)
    800041d8:	e04a                	sd	s2,0(sp)
    800041da:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800041dc:	0001d517          	auipc	a0,0x1d
    800041e0:	bf450513          	addi	a0,a0,-1036 # 80020dd0 <log>
    800041e4:	ffffd097          	auipc	ra,0xffffd
    800041e8:	9f2080e7          	jalr	-1550(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    800041ec:	0001d497          	auipc	s1,0x1d
    800041f0:	be448493          	addi	s1,s1,-1052 # 80020dd0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041f4:	4979                	li	s2,30
    800041f6:	a039                	j	80004204 <begin_op+0x34>
      sleep(&log, &log.lock);
    800041f8:	85a6                	mv	a1,s1
    800041fa:	8526                	mv	a0,s1
    800041fc:	ffffe097          	auipc	ra,0xffffe
    80004200:	e6a080e7          	jalr	-406(ra) # 80002066 <sleep>
    if(log.committing){
    80004204:	50dc                	lw	a5,36(s1)
    80004206:	fbed                	bnez	a5,800041f8 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004208:	5098                	lw	a4,32(s1)
    8000420a:	2705                	addiw	a4,a4,1
    8000420c:	0007069b          	sext.w	a3,a4
    80004210:	0027179b          	slliw	a5,a4,0x2
    80004214:	9fb9                	addw	a5,a5,a4
    80004216:	0017979b          	slliw	a5,a5,0x1
    8000421a:	54d8                	lw	a4,44(s1)
    8000421c:	9fb9                	addw	a5,a5,a4
    8000421e:	00f95963          	bge	s2,a5,80004230 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004222:	85a6                	mv	a1,s1
    80004224:	8526                	mv	a0,s1
    80004226:	ffffe097          	auipc	ra,0xffffe
    8000422a:	e40080e7          	jalr	-448(ra) # 80002066 <sleep>
    8000422e:	bfd9                	j	80004204 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004230:	0001d517          	auipc	a0,0x1d
    80004234:	ba050513          	addi	a0,a0,-1120 # 80020dd0 <log>
    80004238:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000423a:	ffffd097          	auipc	ra,0xffffd
    8000423e:	a50080e7          	jalr	-1456(ra) # 80000c8a <release>
      break;
    }
  }
}
    80004242:	60e2                	ld	ra,24(sp)
    80004244:	6442                	ld	s0,16(sp)
    80004246:	64a2                	ld	s1,8(sp)
    80004248:	6902                	ld	s2,0(sp)
    8000424a:	6105                	addi	sp,sp,32
    8000424c:	8082                	ret

000000008000424e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000424e:	7139                	addi	sp,sp,-64
    80004250:	fc06                	sd	ra,56(sp)
    80004252:	f822                	sd	s0,48(sp)
    80004254:	f426                	sd	s1,40(sp)
    80004256:	f04a                	sd	s2,32(sp)
    80004258:	ec4e                	sd	s3,24(sp)
    8000425a:	e852                	sd	s4,16(sp)
    8000425c:	e456                	sd	s5,8(sp)
    8000425e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004260:	0001d497          	auipc	s1,0x1d
    80004264:	b7048493          	addi	s1,s1,-1168 # 80020dd0 <log>
    80004268:	8526                	mv	a0,s1
    8000426a:	ffffd097          	auipc	ra,0xffffd
    8000426e:	96c080e7          	jalr	-1684(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    80004272:	509c                	lw	a5,32(s1)
    80004274:	37fd                	addiw	a5,a5,-1
    80004276:	0007891b          	sext.w	s2,a5
    8000427a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000427c:	50dc                	lw	a5,36(s1)
    8000427e:	e7b9                	bnez	a5,800042cc <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004280:	04091e63          	bnez	s2,800042dc <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004284:	0001d497          	auipc	s1,0x1d
    80004288:	b4c48493          	addi	s1,s1,-1204 # 80020dd0 <log>
    8000428c:	4785                	li	a5,1
    8000428e:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004290:	8526                	mv	a0,s1
    80004292:	ffffd097          	auipc	ra,0xffffd
    80004296:	9f8080e7          	jalr	-1544(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000429a:	54dc                	lw	a5,44(s1)
    8000429c:	06f04763          	bgtz	a5,8000430a <end_op+0xbc>
    acquire(&log.lock);
    800042a0:	0001d497          	auipc	s1,0x1d
    800042a4:	b3048493          	addi	s1,s1,-1232 # 80020dd0 <log>
    800042a8:	8526                	mv	a0,s1
    800042aa:	ffffd097          	auipc	ra,0xffffd
    800042ae:	92c080e7          	jalr	-1748(ra) # 80000bd6 <acquire>
    log.committing = 0;
    800042b2:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800042b6:	8526                	mv	a0,s1
    800042b8:	ffffe097          	auipc	ra,0xffffe
    800042bc:	e12080e7          	jalr	-494(ra) # 800020ca <wakeup>
    release(&log.lock);
    800042c0:	8526                	mv	a0,s1
    800042c2:	ffffd097          	auipc	ra,0xffffd
    800042c6:	9c8080e7          	jalr	-1592(ra) # 80000c8a <release>
}
    800042ca:	a03d                	j	800042f8 <end_op+0xaa>
    panic("log.committing");
    800042cc:	00004517          	auipc	a0,0x4
    800042d0:	40c50513          	addi	a0,a0,1036 # 800086d8 <syscalls+0x1f0>
    800042d4:	ffffc097          	auipc	ra,0xffffc
    800042d8:	26c080e7          	jalr	620(ra) # 80000540 <panic>
    wakeup(&log);
    800042dc:	0001d497          	auipc	s1,0x1d
    800042e0:	af448493          	addi	s1,s1,-1292 # 80020dd0 <log>
    800042e4:	8526                	mv	a0,s1
    800042e6:	ffffe097          	auipc	ra,0xffffe
    800042ea:	de4080e7          	jalr	-540(ra) # 800020ca <wakeup>
  release(&log.lock);
    800042ee:	8526                	mv	a0,s1
    800042f0:	ffffd097          	auipc	ra,0xffffd
    800042f4:	99a080e7          	jalr	-1638(ra) # 80000c8a <release>
}
    800042f8:	70e2                	ld	ra,56(sp)
    800042fa:	7442                	ld	s0,48(sp)
    800042fc:	74a2                	ld	s1,40(sp)
    800042fe:	7902                	ld	s2,32(sp)
    80004300:	69e2                	ld	s3,24(sp)
    80004302:	6a42                	ld	s4,16(sp)
    80004304:	6aa2                	ld	s5,8(sp)
    80004306:	6121                	addi	sp,sp,64
    80004308:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000430a:	0001da97          	auipc	s5,0x1d
    8000430e:	af6a8a93          	addi	s5,s5,-1290 # 80020e00 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004312:	0001da17          	auipc	s4,0x1d
    80004316:	abea0a13          	addi	s4,s4,-1346 # 80020dd0 <log>
    8000431a:	018a2583          	lw	a1,24(s4)
    8000431e:	012585bb          	addw	a1,a1,s2
    80004322:	2585                	addiw	a1,a1,1
    80004324:	028a2503          	lw	a0,40(s4)
    80004328:	fffff097          	auipc	ra,0xfffff
    8000432c:	cc4080e7          	jalr	-828(ra) # 80002fec <bread>
    80004330:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004332:	000aa583          	lw	a1,0(s5)
    80004336:	028a2503          	lw	a0,40(s4)
    8000433a:	fffff097          	auipc	ra,0xfffff
    8000433e:	cb2080e7          	jalr	-846(ra) # 80002fec <bread>
    80004342:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004344:	40000613          	li	a2,1024
    80004348:	05850593          	addi	a1,a0,88
    8000434c:	05848513          	addi	a0,s1,88
    80004350:	ffffd097          	auipc	ra,0xffffd
    80004354:	9de080e7          	jalr	-1570(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    80004358:	8526                	mv	a0,s1
    8000435a:	fffff097          	auipc	ra,0xfffff
    8000435e:	d84080e7          	jalr	-636(ra) # 800030de <bwrite>
    brelse(from);
    80004362:	854e                	mv	a0,s3
    80004364:	fffff097          	auipc	ra,0xfffff
    80004368:	db8080e7          	jalr	-584(ra) # 8000311c <brelse>
    brelse(to);
    8000436c:	8526                	mv	a0,s1
    8000436e:	fffff097          	auipc	ra,0xfffff
    80004372:	dae080e7          	jalr	-594(ra) # 8000311c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004376:	2905                	addiw	s2,s2,1
    80004378:	0a91                	addi	s5,s5,4
    8000437a:	02ca2783          	lw	a5,44(s4)
    8000437e:	f8f94ee3          	blt	s2,a5,8000431a <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004382:	00000097          	auipc	ra,0x0
    80004386:	c68080e7          	jalr	-920(ra) # 80003fea <write_head>
    install_trans(0); // Now install writes to home locations
    8000438a:	4501                	li	a0,0
    8000438c:	00000097          	auipc	ra,0x0
    80004390:	cda080e7          	jalr	-806(ra) # 80004066 <install_trans>
    log.lh.n = 0;
    80004394:	0001d797          	auipc	a5,0x1d
    80004398:	a607a423          	sw	zero,-1432(a5) # 80020dfc <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000439c:	00000097          	auipc	ra,0x0
    800043a0:	c4e080e7          	jalr	-946(ra) # 80003fea <write_head>
    800043a4:	bdf5                	j	800042a0 <end_op+0x52>

00000000800043a6 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800043a6:	1101                	addi	sp,sp,-32
    800043a8:	ec06                	sd	ra,24(sp)
    800043aa:	e822                	sd	s0,16(sp)
    800043ac:	e426                	sd	s1,8(sp)
    800043ae:	e04a                	sd	s2,0(sp)
    800043b0:	1000                	addi	s0,sp,32
    800043b2:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800043b4:	0001d917          	auipc	s2,0x1d
    800043b8:	a1c90913          	addi	s2,s2,-1508 # 80020dd0 <log>
    800043bc:	854a                	mv	a0,s2
    800043be:	ffffd097          	auipc	ra,0xffffd
    800043c2:	818080e7          	jalr	-2024(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800043c6:	02c92603          	lw	a2,44(s2)
    800043ca:	47f5                	li	a5,29
    800043cc:	06c7c563          	blt	a5,a2,80004436 <log_write+0x90>
    800043d0:	0001d797          	auipc	a5,0x1d
    800043d4:	a1c7a783          	lw	a5,-1508(a5) # 80020dec <log+0x1c>
    800043d8:	37fd                	addiw	a5,a5,-1
    800043da:	04f65e63          	bge	a2,a5,80004436 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800043de:	0001d797          	auipc	a5,0x1d
    800043e2:	a127a783          	lw	a5,-1518(a5) # 80020df0 <log+0x20>
    800043e6:	06f05063          	blez	a5,80004446 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800043ea:	4781                	li	a5,0
    800043ec:	06c05563          	blez	a2,80004456 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800043f0:	44cc                	lw	a1,12(s1)
    800043f2:	0001d717          	auipc	a4,0x1d
    800043f6:	a0e70713          	addi	a4,a4,-1522 # 80020e00 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800043fa:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800043fc:	4314                	lw	a3,0(a4)
    800043fe:	04b68c63          	beq	a3,a1,80004456 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004402:	2785                	addiw	a5,a5,1
    80004404:	0711                	addi	a4,a4,4
    80004406:	fef61be3          	bne	a2,a5,800043fc <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000440a:	0621                	addi	a2,a2,8
    8000440c:	060a                	slli	a2,a2,0x2
    8000440e:	0001d797          	auipc	a5,0x1d
    80004412:	9c278793          	addi	a5,a5,-1598 # 80020dd0 <log>
    80004416:	97b2                	add	a5,a5,a2
    80004418:	44d8                	lw	a4,12(s1)
    8000441a:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000441c:	8526                	mv	a0,s1
    8000441e:	fffff097          	auipc	ra,0xfffff
    80004422:	d9c080e7          	jalr	-612(ra) # 800031ba <bpin>
    log.lh.n++;
    80004426:	0001d717          	auipc	a4,0x1d
    8000442a:	9aa70713          	addi	a4,a4,-1622 # 80020dd0 <log>
    8000442e:	575c                	lw	a5,44(a4)
    80004430:	2785                	addiw	a5,a5,1
    80004432:	d75c                	sw	a5,44(a4)
    80004434:	a82d                	j	8000446e <log_write+0xc8>
    panic("too big a transaction");
    80004436:	00004517          	auipc	a0,0x4
    8000443a:	2b250513          	addi	a0,a0,690 # 800086e8 <syscalls+0x200>
    8000443e:	ffffc097          	auipc	ra,0xffffc
    80004442:	102080e7          	jalr	258(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    80004446:	00004517          	auipc	a0,0x4
    8000444a:	2ba50513          	addi	a0,a0,698 # 80008700 <syscalls+0x218>
    8000444e:	ffffc097          	auipc	ra,0xffffc
    80004452:	0f2080e7          	jalr	242(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    80004456:	00878693          	addi	a3,a5,8
    8000445a:	068a                	slli	a3,a3,0x2
    8000445c:	0001d717          	auipc	a4,0x1d
    80004460:	97470713          	addi	a4,a4,-1676 # 80020dd0 <log>
    80004464:	9736                	add	a4,a4,a3
    80004466:	44d4                	lw	a3,12(s1)
    80004468:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000446a:	faf609e3          	beq	a2,a5,8000441c <log_write+0x76>
  }
  release(&log.lock);
    8000446e:	0001d517          	auipc	a0,0x1d
    80004472:	96250513          	addi	a0,a0,-1694 # 80020dd0 <log>
    80004476:	ffffd097          	auipc	ra,0xffffd
    8000447a:	814080e7          	jalr	-2028(ra) # 80000c8a <release>
}
    8000447e:	60e2                	ld	ra,24(sp)
    80004480:	6442                	ld	s0,16(sp)
    80004482:	64a2                	ld	s1,8(sp)
    80004484:	6902                	ld	s2,0(sp)
    80004486:	6105                	addi	sp,sp,32
    80004488:	8082                	ret

000000008000448a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000448a:	1101                	addi	sp,sp,-32
    8000448c:	ec06                	sd	ra,24(sp)
    8000448e:	e822                	sd	s0,16(sp)
    80004490:	e426                	sd	s1,8(sp)
    80004492:	e04a                	sd	s2,0(sp)
    80004494:	1000                	addi	s0,sp,32
    80004496:	84aa                	mv	s1,a0
    80004498:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000449a:	00004597          	auipc	a1,0x4
    8000449e:	28658593          	addi	a1,a1,646 # 80008720 <syscalls+0x238>
    800044a2:	0521                	addi	a0,a0,8
    800044a4:	ffffc097          	auipc	ra,0xffffc
    800044a8:	6a2080e7          	jalr	1698(ra) # 80000b46 <initlock>
  lk->name = name;
    800044ac:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800044b0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044b4:	0204a423          	sw	zero,40(s1)
}
    800044b8:	60e2                	ld	ra,24(sp)
    800044ba:	6442                	ld	s0,16(sp)
    800044bc:	64a2                	ld	s1,8(sp)
    800044be:	6902                	ld	s2,0(sp)
    800044c0:	6105                	addi	sp,sp,32
    800044c2:	8082                	ret

00000000800044c4 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800044c4:	1101                	addi	sp,sp,-32
    800044c6:	ec06                	sd	ra,24(sp)
    800044c8:	e822                	sd	s0,16(sp)
    800044ca:	e426                	sd	s1,8(sp)
    800044cc:	e04a                	sd	s2,0(sp)
    800044ce:	1000                	addi	s0,sp,32
    800044d0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044d2:	00850913          	addi	s2,a0,8
    800044d6:	854a                	mv	a0,s2
    800044d8:	ffffc097          	auipc	ra,0xffffc
    800044dc:	6fe080e7          	jalr	1790(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    800044e0:	409c                	lw	a5,0(s1)
    800044e2:	cb89                	beqz	a5,800044f4 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800044e4:	85ca                	mv	a1,s2
    800044e6:	8526                	mv	a0,s1
    800044e8:	ffffe097          	auipc	ra,0xffffe
    800044ec:	b7e080e7          	jalr	-1154(ra) # 80002066 <sleep>
  while (lk->locked) {
    800044f0:	409c                	lw	a5,0(s1)
    800044f2:	fbed                	bnez	a5,800044e4 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800044f4:	4785                	li	a5,1
    800044f6:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800044f8:	ffffd097          	auipc	ra,0xffffd
    800044fc:	4b4080e7          	jalr	1204(ra) # 800019ac <myproc>
    80004500:	591c                	lw	a5,48(a0)
    80004502:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004504:	854a                	mv	a0,s2
    80004506:	ffffc097          	auipc	ra,0xffffc
    8000450a:	784080e7          	jalr	1924(ra) # 80000c8a <release>
}
    8000450e:	60e2                	ld	ra,24(sp)
    80004510:	6442                	ld	s0,16(sp)
    80004512:	64a2                	ld	s1,8(sp)
    80004514:	6902                	ld	s2,0(sp)
    80004516:	6105                	addi	sp,sp,32
    80004518:	8082                	ret

000000008000451a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000451a:	1101                	addi	sp,sp,-32
    8000451c:	ec06                	sd	ra,24(sp)
    8000451e:	e822                	sd	s0,16(sp)
    80004520:	e426                	sd	s1,8(sp)
    80004522:	e04a                	sd	s2,0(sp)
    80004524:	1000                	addi	s0,sp,32
    80004526:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004528:	00850913          	addi	s2,a0,8
    8000452c:	854a                	mv	a0,s2
    8000452e:	ffffc097          	auipc	ra,0xffffc
    80004532:	6a8080e7          	jalr	1704(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    80004536:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000453a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000453e:	8526                	mv	a0,s1
    80004540:	ffffe097          	auipc	ra,0xffffe
    80004544:	b8a080e7          	jalr	-1142(ra) # 800020ca <wakeup>
  release(&lk->lk);
    80004548:	854a                	mv	a0,s2
    8000454a:	ffffc097          	auipc	ra,0xffffc
    8000454e:	740080e7          	jalr	1856(ra) # 80000c8a <release>
}
    80004552:	60e2                	ld	ra,24(sp)
    80004554:	6442                	ld	s0,16(sp)
    80004556:	64a2                	ld	s1,8(sp)
    80004558:	6902                	ld	s2,0(sp)
    8000455a:	6105                	addi	sp,sp,32
    8000455c:	8082                	ret

000000008000455e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000455e:	7179                	addi	sp,sp,-48
    80004560:	f406                	sd	ra,40(sp)
    80004562:	f022                	sd	s0,32(sp)
    80004564:	ec26                	sd	s1,24(sp)
    80004566:	e84a                	sd	s2,16(sp)
    80004568:	e44e                	sd	s3,8(sp)
    8000456a:	1800                	addi	s0,sp,48
    8000456c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000456e:	00850913          	addi	s2,a0,8
    80004572:	854a                	mv	a0,s2
    80004574:	ffffc097          	auipc	ra,0xffffc
    80004578:	662080e7          	jalr	1634(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000457c:	409c                	lw	a5,0(s1)
    8000457e:	ef99                	bnez	a5,8000459c <holdingsleep+0x3e>
    80004580:	4481                	li	s1,0
  release(&lk->lk);
    80004582:	854a                	mv	a0,s2
    80004584:	ffffc097          	auipc	ra,0xffffc
    80004588:	706080e7          	jalr	1798(ra) # 80000c8a <release>
  return r;
}
    8000458c:	8526                	mv	a0,s1
    8000458e:	70a2                	ld	ra,40(sp)
    80004590:	7402                	ld	s0,32(sp)
    80004592:	64e2                	ld	s1,24(sp)
    80004594:	6942                	ld	s2,16(sp)
    80004596:	69a2                	ld	s3,8(sp)
    80004598:	6145                	addi	sp,sp,48
    8000459a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000459c:	0284a983          	lw	s3,40(s1)
    800045a0:	ffffd097          	auipc	ra,0xffffd
    800045a4:	40c080e7          	jalr	1036(ra) # 800019ac <myproc>
    800045a8:	5904                	lw	s1,48(a0)
    800045aa:	413484b3          	sub	s1,s1,s3
    800045ae:	0014b493          	seqz	s1,s1
    800045b2:	bfc1                	j	80004582 <holdingsleep+0x24>

00000000800045b4 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800045b4:	1141                	addi	sp,sp,-16
    800045b6:	e406                	sd	ra,8(sp)
    800045b8:	e022                	sd	s0,0(sp)
    800045ba:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800045bc:	00004597          	auipc	a1,0x4
    800045c0:	17458593          	addi	a1,a1,372 # 80008730 <syscalls+0x248>
    800045c4:	0001d517          	auipc	a0,0x1d
    800045c8:	95450513          	addi	a0,a0,-1708 # 80020f18 <ftable>
    800045cc:	ffffc097          	auipc	ra,0xffffc
    800045d0:	57a080e7          	jalr	1402(ra) # 80000b46 <initlock>
}
    800045d4:	60a2                	ld	ra,8(sp)
    800045d6:	6402                	ld	s0,0(sp)
    800045d8:	0141                	addi	sp,sp,16
    800045da:	8082                	ret

00000000800045dc <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800045dc:	1101                	addi	sp,sp,-32
    800045de:	ec06                	sd	ra,24(sp)
    800045e0:	e822                	sd	s0,16(sp)
    800045e2:	e426                	sd	s1,8(sp)
    800045e4:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800045e6:	0001d517          	auipc	a0,0x1d
    800045ea:	93250513          	addi	a0,a0,-1742 # 80020f18 <ftable>
    800045ee:	ffffc097          	auipc	ra,0xffffc
    800045f2:	5e8080e7          	jalr	1512(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045f6:	0001d497          	auipc	s1,0x1d
    800045fa:	93a48493          	addi	s1,s1,-1734 # 80020f30 <ftable+0x18>
    800045fe:	0001e717          	auipc	a4,0x1e
    80004602:	8d270713          	addi	a4,a4,-1838 # 80021ed0 <disk>
    if(f->ref == 0){
    80004606:	40dc                	lw	a5,4(s1)
    80004608:	cf99                	beqz	a5,80004626 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000460a:	02848493          	addi	s1,s1,40
    8000460e:	fee49ce3          	bne	s1,a4,80004606 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004612:	0001d517          	auipc	a0,0x1d
    80004616:	90650513          	addi	a0,a0,-1786 # 80020f18 <ftable>
    8000461a:	ffffc097          	auipc	ra,0xffffc
    8000461e:	670080e7          	jalr	1648(ra) # 80000c8a <release>
  return 0;
    80004622:	4481                	li	s1,0
    80004624:	a819                	j	8000463a <filealloc+0x5e>
      f->ref = 1;
    80004626:	4785                	li	a5,1
    80004628:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000462a:	0001d517          	auipc	a0,0x1d
    8000462e:	8ee50513          	addi	a0,a0,-1810 # 80020f18 <ftable>
    80004632:	ffffc097          	auipc	ra,0xffffc
    80004636:	658080e7          	jalr	1624(ra) # 80000c8a <release>
}
    8000463a:	8526                	mv	a0,s1
    8000463c:	60e2                	ld	ra,24(sp)
    8000463e:	6442                	ld	s0,16(sp)
    80004640:	64a2                	ld	s1,8(sp)
    80004642:	6105                	addi	sp,sp,32
    80004644:	8082                	ret

0000000080004646 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004646:	1101                	addi	sp,sp,-32
    80004648:	ec06                	sd	ra,24(sp)
    8000464a:	e822                	sd	s0,16(sp)
    8000464c:	e426                	sd	s1,8(sp)
    8000464e:	1000                	addi	s0,sp,32
    80004650:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004652:	0001d517          	auipc	a0,0x1d
    80004656:	8c650513          	addi	a0,a0,-1850 # 80020f18 <ftable>
    8000465a:	ffffc097          	auipc	ra,0xffffc
    8000465e:	57c080e7          	jalr	1404(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004662:	40dc                	lw	a5,4(s1)
    80004664:	02f05263          	blez	a5,80004688 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004668:	2785                	addiw	a5,a5,1
    8000466a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000466c:	0001d517          	auipc	a0,0x1d
    80004670:	8ac50513          	addi	a0,a0,-1876 # 80020f18 <ftable>
    80004674:	ffffc097          	auipc	ra,0xffffc
    80004678:	616080e7          	jalr	1558(ra) # 80000c8a <release>
  return f;
}
    8000467c:	8526                	mv	a0,s1
    8000467e:	60e2                	ld	ra,24(sp)
    80004680:	6442                	ld	s0,16(sp)
    80004682:	64a2                	ld	s1,8(sp)
    80004684:	6105                	addi	sp,sp,32
    80004686:	8082                	ret
    panic("filedup");
    80004688:	00004517          	auipc	a0,0x4
    8000468c:	0b050513          	addi	a0,a0,176 # 80008738 <syscalls+0x250>
    80004690:	ffffc097          	auipc	ra,0xffffc
    80004694:	eb0080e7          	jalr	-336(ra) # 80000540 <panic>

0000000080004698 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004698:	7139                	addi	sp,sp,-64
    8000469a:	fc06                	sd	ra,56(sp)
    8000469c:	f822                	sd	s0,48(sp)
    8000469e:	f426                	sd	s1,40(sp)
    800046a0:	f04a                	sd	s2,32(sp)
    800046a2:	ec4e                	sd	s3,24(sp)
    800046a4:	e852                	sd	s4,16(sp)
    800046a6:	e456                	sd	s5,8(sp)
    800046a8:	0080                	addi	s0,sp,64
    800046aa:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800046ac:	0001d517          	auipc	a0,0x1d
    800046b0:	86c50513          	addi	a0,a0,-1940 # 80020f18 <ftable>
    800046b4:	ffffc097          	auipc	ra,0xffffc
    800046b8:	522080e7          	jalr	1314(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    800046bc:	40dc                	lw	a5,4(s1)
    800046be:	06f05163          	blez	a5,80004720 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800046c2:	37fd                	addiw	a5,a5,-1
    800046c4:	0007871b          	sext.w	a4,a5
    800046c8:	c0dc                	sw	a5,4(s1)
    800046ca:	06e04363          	bgtz	a4,80004730 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800046ce:	0004a903          	lw	s2,0(s1)
    800046d2:	0094ca83          	lbu	s5,9(s1)
    800046d6:	0104ba03          	ld	s4,16(s1)
    800046da:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800046de:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800046e2:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800046e6:	0001d517          	auipc	a0,0x1d
    800046ea:	83250513          	addi	a0,a0,-1998 # 80020f18 <ftable>
    800046ee:	ffffc097          	auipc	ra,0xffffc
    800046f2:	59c080e7          	jalr	1436(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    800046f6:	4785                	li	a5,1
    800046f8:	04f90d63          	beq	s2,a5,80004752 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800046fc:	3979                	addiw	s2,s2,-2
    800046fe:	4785                	li	a5,1
    80004700:	0527e063          	bltu	a5,s2,80004740 <fileclose+0xa8>
    begin_op();
    80004704:	00000097          	auipc	ra,0x0
    80004708:	acc080e7          	jalr	-1332(ra) # 800041d0 <begin_op>
    iput(ff.ip);
    8000470c:	854e                	mv	a0,s3
    8000470e:	fffff097          	auipc	ra,0xfffff
    80004712:	2b0080e7          	jalr	688(ra) # 800039be <iput>
    end_op();
    80004716:	00000097          	auipc	ra,0x0
    8000471a:	b38080e7          	jalr	-1224(ra) # 8000424e <end_op>
    8000471e:	a00d                	j	80004740 <fileclose+0xa8>
    panic("fileclose");
    80004720:	00004517          	auipc	a0,0x4
    80004724:	02050513          	addi	a0,a0,32 # 80008740 <syscalls+0x258>
    80004728:	ffffc097          	auipc	ra,0xffffc
    8000472c:	e18080e7          	jalr	-488(ra) # 80000540 <panic>
    release(&ftable.lock);
    80004730:	0001c517          	auipc	a0,0x1c
    80004734:	7e850513          	addi	a0,a0,2024 # 80020f18 <ftable>
    80004738:	ffffc097          	auipc	ra,0xffffc
    8000473c:	552080e7          	jalr	1362(ra) # 80000c8a <release>
  }
}
    80004740:	70e2                	ld	ra,56(sp)
    80004742:	7442                	ld	s0,48(sp)
    80004744:	74a2                	ld	s1,40(sp)
    80004746:	7902                	ld	s2,32(sp)
    80004748:	69e2                	ld	s3,24(sp)
    8000474a:	6a42                	ld	s4,16(sp)
    8000474c:	6aa2                	ld	s5,8(sp)
    8000474e:	6121                	addi	sp,sp,64
    80004750:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004752:	85d6                	mv	a1,s5
    80004754:	8552                	mv	a0,s4
    80004756:	00000097          	auipc	ra,0x0
    8000475a:	34c080e7          	jalr	844(ra) # 80004aa2 <pipeclose>
    8000475e:	b7cd                	j	80004740 <fileclose+0xa8>

0000000080004760 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004760:	715d                	addi	sp,sp,-80
    80004762:	e486                	sd	ra,72(sp)
    80004764:	e0a2                	sd	s0,64(sp)
    80004766:	fc26                	sd	s1,56(sp)
    80004768:	f84a                	sd	s2,48(sp)
    8000476a:	f44e                	sd	s3,40(sp)
    8000476c:	0880                	addi	s0,sp,80
    8000476e:	84aa                	mv	s1,a0
    80004770:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004772:	ffffd097          	auipc	ra,0xffffd
    80004776:	23a080e7          	jalr	570(ra) # 800019ac <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000477a:	409c                	lw	a5,0(s1)
    8000477c:	37f9                	addiw	a5,a5,-2
    8000477e:	4705                	li	a4,1
    80004780:	04f76763          	bltu	a4,a5,800047ce <filestat+0x6e>
    80004784:	892a                	mv	s2,a0
    ilock(f->ip);
    80004786:	6c88                	ld	a0,24(s1)
    80004788:	fffff097          	auipc	ra,0xfffff
    8000478c:	07c080e7          	jalr	124(ra) # 80003804 <ilock>
    stati(f->ip, &st);
    80004790:	fb840593          	addi	a1,s0,-72
    80004794:	6c88                	ld	a0,24(s1)
    80004796:	fffff097          	auipc	ra,0xfffff
    8000479a:	2f8080e7          	jalr	760(ra) # 80003a8e <stati>
    iunlock(f->ip);
    8000479e:	6c88                	ld	a0,24(s1)
    800047a0:	fffff097          	auipc	ra,0xfffff
    800047a4:	126080e7          	jalr	294(ra) # 800038c6 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800047a8:	46e1                	li	a3,24
    800047aa:	fb840613          	addi	a2,s0,-72
    800047ae:	85ce                	mv	a1,s3
    800047b0:	05093503          	ld	a0,80(s2)
    800047b4:	ffffd097          	auipc	ra,0xffffd
    800047b8:	eb8080e7          	jalr	-328(ra) # 8000166c <copyout>
    800047bc:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800047c0:	60a6                	ld	ra,72(sp)
    800047c2:	6406                	ld	s0,64(sp)
    800047c4:	74e2                	ld	s1,56(sp)
    800047c6:	7942                	ld	s2,48(sp)
    800047c8:	79a2                	ld	s3,40(sp)
    800047ca:	6161                	addi	sp,sp,80
    800047cc:	8082                	ret
  return -1;
    800047ce:	557d                	li	a0,-1
    800047d0:	bfc5                	j	800047c0 <filestat+0x60>

00000000800047d2 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800047d2:	7179                	addi	sp,sp,-48
    800047d4:	f406                	sd	ra,40(sp)
    800047d6:	f022                	sd	s0,32(sp)
    800047d8:	ec26                	sd	s1,24(sp)
    800047da:	e84a                	sd	s2,16(sp)
    800047dc:	e44e                	sd	s3,8(sp)
    800047de:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800047e0:	00854783          	lbu	a5,8(a0)
    800047e4:	c3d5                	beqz	a5,80004888 <fileread+0xb6>
    800047e6:	84aa                	mv	s1,a0
    800047e8:	89ae                	mv	s3,a1
    800047ea:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800047ec:	411c                	lw	a5,0(a0)
    800047ee:	4705                	li	a4,1
    800047f0:	04e78963          	beq	a5,a4,80004842 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047f4:	470d                	li	a4,3
    800047f6:	04e78d63          	beq	a5,a4,80004850 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800047fa:	4709                	li	a4,2
    800047fc:	06e79e63          	bne	a5,a4,80004878 <fileread+0xa6>
    ilock(f->ip);
    80004800:	6d08                	ld	a0,24(a0)
    80004802:	fffff097          	auipc	ra,0xfffff
    80004806:	002080e7          	jalr	2(ra) # 80003804 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000480a:	874a                	mv	a4,s2
    8000480c:	5094                	lw	a3,32(s1)
    8000480e:	864e                	mv	a2,s3
    80004810:	4585                	li	a1,1
    80004812:	6c88                	ld	a0,24(s1)
    80004814:	fffff097          	auipc	ra,0xfffff
    80004818:	2a4080e7          	jalr	676(ra) # 80003ab8 <readi>
    8000481c:	892a                	mv	s2,a0
    8000481e:	00a05563          	blez	a0,80004828 <fileread+0x56>
      f->off += r;
    80004822:	509c                	lw	a5,32(s1)
    80004824:	9fa9                	addw	a5,a5,a0
    80004826:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004828:	6c88                	ld	a0,24(s1)
    8000482a:	fffff097          	auipc	ra,0xfffff
    8000482e:	09c080e7          	jalr	156(ra) # 800038c6 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004832:	854a                	mv	a0,s2
    80004834:	70a2                	ld	ra,40(sp)
    80004836:	7402                	ld	s0,32(sp)
    80004838:	64e2                	ld	s1,24(sp)
    8000483a:	6942                	ld	s2,16(sp)
    8000483c:	69a2                	ld	s3,8(sp)
    8000483e:	6145                	addi	sp,sp,48
    80004840:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004842:	6908                	ld	a0,16(a0)
    80004844:	00000097          	auipc	ra,0x0
    80004848:	3c6080e7          	jalr	966(ra) # 80004c0a <piperead>
    8000484c:	892a                	mv	s2,a0
    8000484e:	b7d5                	j	80004832 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004850:	02451783          	lh	a5,36(a0)
    80004854:	03079693          	slli	a3,a5,0x30
    80004858:	92c1                	srli	a3,a3,0x30
    8000485a:	4725                	li	a4,9
    8000485c:	02d76863          	bltu	a4,a3,8000488c <fileread+0xba>
    80004860:	0792                	slli	a5,a5,0x4
    80004862:	0001c717          	auipc	a4,0x1c
    80004866:	61670713          	addi	a4,a4,1558 # 80020e78 <devsw>
    8000486a:	97ba                	add	a5,a5,a4
    8000486c:	639c                	ld	a5,0(a5)
    8000486e:	c38d                	beqz	a5,80004890 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004870:	4505                	li	a0,1
    80004872:	9782                	jalr	a5
    80004874:	892a                	mv	s2,a0
    80004876:	bf75                	j	80004832 <fileread+0x60>
    panic("fileread");
    80004878:	00004517          	auipc	a0,0x4
    8000487c:	ed850513          	addi	a0,a0,-296 # 80008750 <syscalls+0x268>
    80004880:	ffffc097          	auipc	ra,0xffffc
    80004884:	cc0080e7          	jalr	-832(ra) # 80000540 <panic>
    return -1;
    80004888:	597d                	li	s2,-1
    8000488a:	b765                	j	80004832 <fileread+0x60>
      return -1;
    8000488c:	597d                	li	s2,-1
    8000488e:	b755                	j	80004832 <fileread+0x60>
    80004890:	597d                	li	s2,-1
    80004892:	b745                	j	80004832 <fileread+0x60>

0000000080004894 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004894:	715d                	addi	sp,sp,-80
    80004896:	e486                	sd	ra,72(sp)
    80004898:	e0a2                	sd	s0,64(sp)
    8000489a:	fc26                	sd	s1,56(sp)
    8000489c:	f84a                	sd	s2,48(sp)
    8000489e:	f44e                	sd	s3,40(sp)
    800048a0:	f052                	sd	s4,32(sp)
    800048a2:	ec56                	sd	s5,24(sp)
    800048a4:	e85a                	sd	s6,16(sp)
    800048a6:	e45e                	sd	s7,8(sp)
    800048a8:	e062                	sd	s8,0(sp)
    800048aa:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800048ac:	00954783          	lbu	a5,9(a0)
    800048b0:	10078663          	beqz	a5,800049bc <filewrite+0x128>
    800048b4:	892a                	mv	s2,a0
    800048b6:	8b2e                	mv	s6,a1
    800048b8:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800048ba:	411c                	lw	a5,0(a0)
    800048bc:	4705                	li	a4,1
    800048be:	02e78263          	beq	a5,a4,800048e2 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048c2:	470d                	li	a4,3
    800048c4:	02e78663          	beq	a5,a4,800048f0 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800048c8:	4709                	li	a4,2
    800048ca:	0ee79163          	bne	a5,a4,800049ac <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800048ce:	0ac05d63          	blez	a2,80004988 <filewrite+0xf4>
    int i = 0;
    800048d2:	4981                	li	s3,0
    800048d4:	6b85                	lui	s7,0x1
    800048d6:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    800048da:	6c05                	lui	s8,0x1
    800048dc:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    800048e0:	a861                	j	80004978 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800048e2:	6908                	ld	a0,16(a0)
    800048e4:	00000097          	auipc	ra,0x0
    800048e8:	22e080e7          	jalr	558(ra) # 80004b12 <pipewrite>
    800048ec:	8a2a                	mv	s4,a0
    800048ee:	a045                	j	8000498e <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800048f0:	02451783          	lh	a5,36(a0)
    800048f4:	03079693          	slli	a3,a5,0x30
    800048f8:	92c1                	srli	a3,a3,0x30
    800048fa:	4725                	li	a4,9
    800048fc:	0cd76263          	bltu	a4,a3,800049c0 <filewrite+0x12c>
    80004900:	0792                	slli	a5,a5,0x4
    80004902:	0001c717          	auipc	a4,0x1c
    80004906:	57670713          	addi	a4,a4,1398 # 80020e78 <devsw>
    8000490a:	97ba                	add	a5,a5,a4
    8000490c:	679c                	ld	a5,8(a5)
    8000490e:	cbdd                	beqz	a5,800049c4 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004910:	4505                	li	a0,1
    80004912:	9782                	jalr	a5
    80004914:	8a2a                	mv	s4,a0
    80004916:	a8a5                	j	8000498e <filewrite+0xfa>
    80004918:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000491c:	00000097          	auipc	ra,0x0
    80004920:	8b4080e7          	jalr	-1868(ra) # 800041d0 <begin_op>
      ilock(f->ip);
    80004924:	01893503          	ld	a0,24(s2)
    80004928:	fffff097          	auipc	ra,0xfffff
    8000492c:	edc080e7          	jalr	-292(ra) # 80003804 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004930:	8756                	mv	a4,s5
    80004932:	02092683          	lw	a3,32(s2)
    80004936:	01698633          	add	a2,s3,s6
    8000493a:	4585                	li	a1,1
    8000493c:	01893503          	ld	a0,24(s2)
    80004940:	fffff097          	auipc	ra,0xfffff
    80004944:	270080e7          	jalr	624(ra) # 80003bb0 <writei>
    80004948:	84aa                	mv	s1,a0
    8000494a:	00a05763          	blez	a0,80004958 <filewrite+0xc4>
        f->off += r;
    8000494e:	02092783          	lw	a5,32(s2)
    80004952:	9fa9                	addw	a5,a5,a0
    80004954:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004958:	01893503          	ld	a0,24(s2)
    8000495c:	fffff097          	auipc	ra,0xfffff
    80004960:	f6a080e7          	jalr	-150(ra) # 800038c6 <iunlock>
      end_op();
    80004964:	00000097          	auipc	ra,0x0
    80004968:	8ea080e7          	jalr	-1814(ra) # 8000424e <end_op>

      if(r != n1){
    8000496c:	009a9f63          	bne	s5,s1,8000498a <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004970:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004974:	0149db63          	bge	s3,s4,8000498a <filewrite+0xf6>
      int n1 = n - i;
    80004978:	413a04bb          	subw	s1,s4,s3
    8000497c:	0004879b          	sext.w	a5,s1
    80004980:	f8fbdce3          	bge	s7,a5,80004918 <filewrite+0x84>
    80004984:	84e2                	mv	s1,s8
    80004986:	bf49                	j	80004918 <filewrite+0x84>
    int i = 0;
    80004988:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000498a:	013a1f63          	bne	s4,s3,800049a8 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000498e:	8552                	mv	a0,s4
    80004990:	60a6                	ld	ra,72(sp)
    80004992:	6406                	ld	s0,64(sp)
    80004994:	74e2                	ld	s1,56(sp)
    80004996:	7942                	ld	s2,48(sp)
    80004998:	79a2                	ld	s3,40(sp)
    8000499a:	7a02                	ld	s4,32(sp)
    8000499c:	6ae2                	ld	s5,24(sp)
    8000499e:	6b42                	ld	s6,16(sp)
    800049a0:	6ba2                	ld	s7,8(sp)
    800049a2:	6c02                	ld	s8,0(sp)
    800049a4:	6161                	addi	sp,sp,80
    800049a6:	8082                	ret
    ret = (i == n ? n : -1);
    800049a8:	5a7d                	li	s4,-1
    800049aa:	b7d5                	j	8000498e <filewrite+0xfa>
    panic("filewrite");
    800049ac:	00004517          	auipc	a0,0x4
    800049b0:	db450513          	addi	a0,a0,-588 # 80008760 <syscalls+0x278>
    800049b4:	ffffc097          	auipc	ra,0xffffc
    800049b8:	b8c080e7          	jalr	-1140(ra) # 80000540 <panic>
    return -1;
    800049bc:	5a7d                	li	s4,-1
    800049be:	bfc1                	j	8000498e <filewrite+0xfa>
      return -1;
    800049c0:	5a7d                	li	s4,-1
    800049c2:	b7f1                	j	8000498e <filewrite+0xfa>
    800049c4:	5a7d                	li	s4,-1
    800049c6:	b7e1                	j	8000498e <filewrite+0xfa>

00000000800049c8 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800049c8:	7179                	addi	sp,sp,-48
    800049ca:	f406                	sd	ra,40(sp)
    800049cc:	f022                	sd	s0,32(sp)
    800049ce:	ec26                	sd	s1,24(sp)
    800049d0:	e84a                	sd	s2,16(sp)
    800049d2:	e44e                	sd	s3,8(sp)
    800049d4:	e052                	sd	s4,0(sp)
    800049d6:	1800                	addi	s0,sp,48
    800049d8:	84aa                	mv	s1,a0
    800049da:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800049dc:	0005b023          	sd	zero,0(a1)
    800049e0:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800049e4:	00000097          	auipc	ra,0x0
    800049e8:	bf8080e7          	jalr	-1032(ra) # 800045dc <filealloc>
    800049ec:	e088                	sd	a0,0(s1)
    800049ee:	c551                	beqz	a0,80004a7a <pipealloc+0xb2>
    800049f0:	00000097          	auipc	ra,0x0
    800049f4:	bec080e7          	jalr	-1044(ra) # 800045dc <filealloc>
    800049f8:	00aa3023          	sd	a0,0(s4)
    800049fc:	c92d                	beqz	a0,80004a6e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800049fe:	ffffc097          	auipc	ra,0xffffc
    80004a02:	0e8080e7          	jalr	232(ra) # 80000ae6 <kalloc>
    80004a06:	892a                	mv	s2,a0
    80004a08:	c125                	beqz	a0,80004a68 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004a0a:	4985                	li	s3,1
    80004a0c:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a10:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004a14:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004a18:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a1c:	00004597          	auipc	a1,0x4
    80004a20:	d5458593          	addi	a1,a1,-684 # 80008770 <syscalls+0x288>
    80004a24:	ffffc097          	auipc	ra,0xffffc
    80004a28:	122080e7          	jalr	290(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004a2c:	609c                	ld	a5,0(s1)
    80004a2e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a32:	609c                	ld	a5,0(s1)
    80004a34:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a38:	609c                	ld	a5,0(s1)
    80004a3a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a3e:	609c                	ld	a5,0(s1)
    80004a40:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a44:	000a3783          	ld	a5,0(s4)
    80004a48:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a4c:	000a3783          	ld	a5,0(s4)
    80004a50:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a54:	000a3783          	ld	a5,0(s4)
    80004a58:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a5c:	000a3783          	ld	a5,0(s4)
    80004a60:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a64:	4501                	li	a0,0
    80004a66:	a025                	j	80004a8e <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a68:	6088                	ld	a0,0(s1)
    80004a6a:	e501                	bnez	a0,80004a72 <pipealloc+0xaa>
    80004a6c:	a039                	j	80004a7a <pipealloc+0xb2>
    80004a6e:	6088                	ld	a0,0(s1)
    80004a70:	c51d                	beqz	a0,80004a9e <pipealloc+0xd6>
    fileclose(*f0);
    80004a72:	00000097          	auipc	ra,0x0
    80004a76:	c26080e7          	jalr	-986(ra) # 80004698 <fileclose>
  if(*f1)
    80004a7a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a7e:	557d                	li	a0,-1
  if(*f1)
    80004a80:	c799                	beqz	a5,80004a8e <pipealloc+0xc6>
    fileclose(*f1);
    80004a82:	853e                	mv	a0,a5
    80004a84:	00000097          	auipc	ra,0x0
    80004a88:	c14080e7          	jalr	-1004(ra) # 80004698 <fileclose>
  return -1;
    80004a8c:	557d                	li	a0,-1
}
    80004a8e:	70a2                	ld	ra,40(sp)
    80004a90:	7402                	ld	s0,32(sp)
    80004a92:	64e2                	ld	s1,24(sp)
    80004a94:	6942                	ld	s2,16(sp)
    80004a96:	69a2                	ld	s3,8(sp)
    80004a98:	6a02                	ld	s4,0(sp)
    80004a9a:	6145                	addi	sp,sp,48
    80004a9c:	8082                	ret
  return -1;
    80004a9e:	557d                	li	a0,-1
    80004aa0:	b7fd                	j	80004a8e <pipealloc+0xc6>

0000000080004aa2 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004aa2:	1101                	addi	sp,sp,-32
    80004aa4:	ec06                	sd	ra,24(sp)
    80004aa6:	e822                	sd	s0,16(sp)
    80004aa8:	e426                	sd	s1,8(sp)
    80004aaa:	e04a                	sd	s2,0(sp)
    80004aac:	1000                	addi	s0,sp,32
    80004aae:	84aa                	mv	s1,a0
    80004ab0:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004ab2:	ffffc097          	auipc	ra,0xffffc
    80004ab6:	124080e7          	jalr	292(ra) # 80000bd6 <acquire>
  if(writable){
    80004aba:	02090d63          	beqz	s2,80004af4 <pipeclose+0x52>
    pi->writeopen = 0;
    80004abe:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004ac2:	21848513          	addi	a0,s1,536
    80004ac6:	ffffd097          	auipc	ra,0xffffd
    80004aca:	604080e7          	jalr	1540(ra) # 800020ca <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004ace:	2204b783          	ld	a5,544(s1)
    80004ad2:	eb95                	bnez	a5,80004b06 <pipeclose+0x64>
    release(&pi->lock);
    80004ad4:	8526                	mv	a0,s1
    80004ad6:	ffffc097          	auipc	ra,0xffffc
    80004ada:	1b4080e7          	jalr	436(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004ade:	8526                	mv	a0,s1
    80004ae0:	ffffc097          	auipc	ra,0xffffc
    80004ae4:	f08080e7          	jalr	-248(ra) # 800009e8 <kfree>
  } else
    release(&pi->lock);
}
    80004ae8:	60e2                	ld	ra,24(sp)
    80004aea:	6442                	ld	s0,16(sp)
    80004aec:	64a2                	ld	s1,8(sp)
    80004aee:	6902                	ld	s2,0(sp)
    80004af0:	6105                	addi	sp,sp,32
    80004af2:	8082                	ret
    pi->readopen = 0;
    80004af4:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004af8:	21c48513          	addi	a0,s1,540
    80004afc:	ffffd097          	auipc	ra,0xffffd
    80004b00:	5ce080e7          	jalr	1486(ra) # 800020ca <wakeup>
    80004b04:	b7e9                	j	80004ace <pipeclose+0x2c>
    release(&pi->lock);
    80004b06:	8526                	mv	a0,s1
    80004b08:	ffffc097          	auipc	ra,0xffffc
    80004b0c:	182080e7          	jalr	386(ra) # 80000c8a <release>
}
    80004b10:	bfe1                	j	80004ae8 <pipeclose+0x46>

0000000080004b12 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b12:	711d                	addi	sp,sp,-96
    80004b14:	ec86                	sd	ra,88(sp)
    80004b16:	e8a2                	sd	s0,80(sp)
    80004b18:	e4a6                	sd	s1,72(sp)
    80004b1a:	e0ca                	sd	s2,64(sp)
    80004b1c:	fc4e                	sd	s3,56(sp)
    80004b1e:	f852                	sd	s4,48(sp)
    80004b20:	f456                	sd	s5,40(sp)
    80004b22:	f05a                	sd	s6,32(sp)
    80004b24:	ec5e                	sd	s7,24(sp)
    80004b26:	e862                	sd	s8,16(sp)
    80004b28:	1080                	addi	s0,sp,96
    80004b2a:	84aa                	mv	s1,a0
    80004b2c:	8aae                	mv	s5,a1
    80004b2e:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004b30:	ffffd097          	auipc	ra,0xffffd
    80004b34:	e7c080e7          	jalr	-388(ra) # 800019ac <myproc>
    80004b38:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004b3a:	8526                	mv	a0,s1
    80004b3c:	ffffc097          	auipc	ra,0xffffc
    80004b40:	09a080e7          	jalr	154(ra) # 80000bd6 <acquire>
  while(i < n){
    80004b44:	0b405663          	blez	s4,80004bf0 <pipewrite+0xde>
  int i = 0;
    80004b48:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b4a:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004b4c:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b50:	21c48b93          	addi	s7,s1,540
    80004b54:	a089                	j	80004b96 <pipewrite+0x84>
      release(&pi->lock);
    80004b56:	8526                	mv	a0,s1
    80004b58:	ffffc097          	auipc	ra,0xffffc
    80004b5c:	132080e7          	jalr	306(ra) # 80000c8a <release>
      return -1;
    80004b60:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b62:	854a                	mv	a0,s2
    80004b64:	60e6                	ld	ra,88(sp)
    80004b66:	6446                	ld	s0,80(sp)
    80004b68:	64a6                	ld	s1,72(sp)
    80004b6a:	6906                	ld	s2,64(sp)
    80004b6c:	79e2                	ld	s3,56(sp)
    80004b6e:	7a42                	ld	s4,48(sp)
    80004b70:	7aa2                	ld	s5,40(sp)
    80004b72:	7b02                	ld	s6,32(sp)
    80004b74:	6be2                	ld	s7,24(sp)
    80004b76:	6c42                	ld	s8,16(sp)
    80004b78:	6125                	addi	sp,sp,96
    80004b7a:	8082                	ret
      wakeup(&pi->nread);
    80004b7c:	8562                	mv	a0,s8
    80004b7e:	ffffd097          	auipc	ra,0xffffd
    80004b82:	54c080e7          	jalr	1356(ra) # 800020ca <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b86:	85a6                	mv	a1,s1
    80004b88:	855e                	mv	a0,s7
    80004b8a:	ffffd097          	auipc	ra,0xffffd
    80004b8e:	4dc080e7          	jalr	1244(ra) # 80002066 <sleep>
  while(i < n){
    80004b92:	07495063          	bge	s2,s4,80004bf2 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004b96:	2204a783          	lw	a5,544(s1)
    80004b9a:	dfd5                	beqz	a5,80004b56 <pipewrite+0x44>
    80004b9c:	854e                	mv	a0,s3
    80004b9e:	ffffd097          	auipc	ra,0xffffd
    80004ba2:	770080e7          	jalr	1904(ra) # 8000230e <killed>
    80004ba6:	f945                	bnez	a0,80004b56 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004ba8:	2184a783          	lw	a5,536(s1)
    80004bac:	21c4a703          	lw	a4,540(s1)
    80004bb0:	2007879b          	addiw	a5,a5,512
    80004bb4:	fcf704e3          	beq	a4,a5,80004b7c <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004bb8:	4685                	li	a3,1
    80004bba:	01590633          	add	a2,s2,s5
    80004bbe:	faf40593          	addi	a1,s0,-81
    80004bc2:	0509b503          	ld	a0,80(s3)
    80004bc6:	ffffd097          	auipc	ra,0xffffd
    80004bca:	b32080e7          	jalr	-1230(ra) # 800016f8 <copyin>
    80004bce:	03650263          	beq	a0,s6,80004bf2 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004bd2:	21c4a783          	lw	a5,540(s1)
    80004bd6:	0017871b          	addiw	a4,a5,1
    80004bda:	20e4ae23          	sw	a4,540(s1)
    80004bde:	1ff7f793          	andi	a5,a5,511
    80004be2:	97a6                	add	a5,a5,s1
    80004be4:	faf44703          	lbu	a4,-81(s0)
    80004be8:	00e78c23          	sb	a4,24(a5)
      i++;
    80004bec:	2905                	addiw	s2,s2,1
    80004bee:	b755                	j	80004b92 <pipewrite+0x80>
  int i = 0;
    80004bf0:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004bf2:	21848513          	addi	a0,s1,536
    80004bf6:	ffffd097          	auipc	ra,0xffffd
    80004bfa:	4d4080e7          	jalr	1236(ra) # 800020ca <wakeup>
  release(&pi->lock);
    80004bfe:	8526                	mv	a0,s1
    80004c00:	ffffc097          	auipc	ra,0xffffc
    80004c04:	08a080e7          	jalr	138(ra) # 80000c8a <release>
  return i;
    80004c08:	bfa9                	j	80004b62 <pipewrite+0x50>

0000000080004c0a <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c0a:	715d                	addi	sp,sp,-80
    80004c0c:	e486                	sd	ra,72(sp)
    80004c0e:	e0a2                	sd	s0,64(sp)
    80004c10:	fc26                	sd	s1,56(sp)
    80004c12:	f84a                	sd	s2,48(sp)
    80004c14:	f44e                	sd	s3,40(sp)
    80004c16:	f052                	sd	s4,32(sp)
    80004c18:	ec56                	sd	s5,24(sp)
    80004c1a:	e85a                	sd	s6,16(sp)
    80004c1c:	0880                	addi	s0,sp,80
    80004c1e:	84aa                	mv	s1,a0
    80004c20:	892e                	mv	s2,a1
    80004c22:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004c24:	ffffd097          	auipc	ra,0xffffd
    80004c28:	d88080e7          	jalr	-632(ra) # 800019ac <myproc>
    80004c2c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c2e:	8526                	mv	a0,s1
    80004c30:	ffffc097          	auipc	ra,0xffffc
    80004c34:	fa6080e7          	jalr	-90(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c38:	2184a703          	lw	a4,536(s1)
    80004c3c:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c40:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c44:	02f71763          	bne	a4,a5,80004c72 <piperead+0x68>
    80004c48:	2244a783          	lw	a5,548(s1)
    80004c4c:	c39d                	beqz	a5,80004c72 <piperead+0x68>
    if(killed(pr)){
    80004c4e:	8552                	mv	a0,s4
    80004c50:	ffffd097          	auipc	ra,0xffffd
    80004c54:	6be080e7          	jalr	1726(ra) # 8000230e <killed>
    80004c58:	e949                	bnez	a0,80004cea <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c5a:	85a6                	mv	a1,s1
    80004c5c:	854e                	mv	a0,s3
    80004c5e:	ffffd097          	auipc	ra,0xffffd
    80004c62:	408080e7          	jalr	1032(ra) # 80002066 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c66:	2184a703          	lw	a4,536(s1)
    80004c6a:	21c4a783          	lw	a5,540(s1)
    80004c6e:	fcf70de3          	beq	a4,a5,80004c48 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c72:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c74:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c76:	05505463          	blez	s5,80004cbe <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004c7a:	2184a783          	lw	a5,536(s1)
    80004c7e:	21c4a703          	lw	a4,540(s1)
    80004c82:	02f70e63          	beq	a4,a5,80004cbe <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c86:	0017871b          	addiw	a4,a5,1
    80004c8a:	20e4ac23          	sw	a4,536(s1)
    80004c8e:	1ff7f793          	andi	a5,a5,511
    80004c92:	97a6                	add	a5,a5,s1
    80004c94:	0187c783          	lbu	a5,24(a5)
    80004c98:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c9c:	4685                	li	a3,1
    80004c9e:	fbf40613          	addi	a2,s0,-65
    80004ca2:	85ca                	mv	a1,s2
    80004ca4:	050a3503          	ld	a0,80(s4)
    80004ca8:	ffffd097          	auipc	ra,0xffffd
    80004cac:	9c4080e7          	jalr	-1596(ra) # 8000166c <copyout>
    80004cb0:	01650763          	beq	a0,s6,80004cbe <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cb4:	2985                	addiw	s3,s3,1
    80004cb6:	0905                	addi	s2,s2,1
    80004cb8:	fd3a91e3          	bne	s5,s3,80004c7a <piperead+0x70>
    80004cbc:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004cbe:	21c48513          	addi	a0,s1,540
    80004cc2:	ffffd097          	auipc	ra,0xffffd
    80004cc6:	408080e7          	jalr	1032(ra) # 800020ca <wakeup>
  release(&pi->lock);
    80004cca:	8526                	mv	a0,s1
    80004ccc:	ffffc097          	auipc	ra,0xffffc
    80004cd0:	fbe080e7          	jalr	-66(ra) # 80000c8a <release>
  return i;
}
    80004cd4:	854e                	mv	a0,s3
    80004cd6:	60a6                	ld	ra,72(sp)
    80004cd8:	6406                	ld	s0,64(sp)
    80004cda:	74e2                	ld	s1,56(sp)
    80004cdc:	7942                	ld	s2,48(sp)
    80004cde:	79a2                	ld	s3,40(sp)
    80004ce0:	7a02                	ld	s4,32(sp)
    80004ce2:	6ae2                	ld	s5,24(sp)
    80004ce4:	6b42                	ld	s6,16(sp)
    80004ce6:	6161                	addi	sp,sp,80
    80004ce8:	8082                	ret
      release(&pi->lock);
    80004cea:	8526                	mv	a0,s1
    80004cec:	ffffc097          	auipc	ra,0xffffc
    80004cf0:	f9e080e7          	jalr	-98(ra) # 80000c8a <release>
      return -1;
    80004cf4:	59fd                	li	s3,-1
    80004cf6:	bff9                	j	80004cd4 <piperead+0xca>

0000000080004cf8 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004cf8:	1141                	addi	sp,sp,-16
    80004cfa:	e422                	sd	s0,8(sp)
    80004cfc:	0800                	addi	s0,sp,16
    80004cfe:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004d00:	8905                	andi	a0,a0,1
    80004d02:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004d04:	8b89                	andi	a5,a5,2
    80004d06:	c399                	beqz	a5,80004d0c <flags2perm+0x14>
      perm |= PTE_W;
    80004d08:	00456513          	ori	a0,a0,4
    return perm;
}
    80004d0c:	6422                	ld	s0,8(sp)
    80004d0e:	0141                	addi	sp,sp,16
    80004d10:	8082                	ret

0000000080004d12 <exec>:

int
exec(char *path, char **argv)
{
    80004d12:	de010113          	addi	sp,sp,-544
    80004d16:	20113c23          	sd	ra,536(sp)
    80004d1a:	20813823          	sd	s0,528(sp)
    80004d1e:	20913423          	sd	s1,520(sp)
    80004d22:	21213023          	sd	s2,512(sp)
    80004d26:	ffce                	sd	s3,504(sp)
    80004d28:	fbd2                	sd	s4,496(sp)
    80004d2a:	f7d6                	sd	s5,488(sp)
    80004d2c:	f3da                	sd	s6,480(sp)
    80004d2e:	efde                	sd	s7,472(sp)
    80004d30:	ebe2                	sd	s8,464(sp)
    80004d32:	e7e6                	sd	s9,456(sp)
    80004d34:	e3ea                	sd	s10,448(sp)
    80004d36:	ff6e                	sd	s11,440(sp)
    80004d38:	1400                	addi	s0,sp,544
    80004d3a:	892a                	mv	s2,a0
    80004d3c:	dea43423          	sd	a0,-536(s0)
    80004d40:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d44:	ffffd097          	auipc	ra,0xffffd
    80004d48:	c68080e7          	jalr	-920(ra) # 800019ac <myproc>
    80004d4c:	84aa                	mv	s1,a0

  begin_op();
    80004d4e:	fffff097          	auipc	ra,0xfffff
    80004d52:	482080e7          	jalr	1154(ra) # 800041d0 <begin_op>

  if((ip = namei(path)) == 0){
    80004d56:	854a                	mv	a0,s2
    80004d58:	fffff097          	auipc	ra,0xfffff
    80004d5c:	258080e7          	jalr	600(ra) # 80003fb0 <namei>
    80004d60:	c93d                	beqz	a0,80004dd6 <exec+0xc4>
    80004d62:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d64:	fffff097          	auipc	ra,0xfffff
    80004d68:	aa0080e7          	jalr	-1376(ra) # 80003804 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d6c:	04000713          	li	a4,64
    80004d70:	4681                	li	a3,0
    80004d72:	e5040613          	addi	a2,s0,-432
    80004d76:	4581                	li	a1,0
    80004d78:	8556                	mv	a0,s5
    80004d7a:	fffff097          	auipc	ra,0xfffff
    80004d7e:	d3e080e7          	jalr	-706(ra) # 80003ab8 <readi>
    80004d82:	04000793          	li	a5,64
    80004d86:	00f51a63          	bne	a0,a5,80004d9a <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004d8a:	e5042703          	lw	a4,-432(s0)
    80004d8e:	464c47b7          	lui	a5,0x464c4
    80004d92:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d96:	04f70663          	beq	a4,a5,80004de2 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d9a:	8556                	mv	a0,s5
    80004d9c:	fffff097          	auipc	ra,0xfffff
    80004da0:	cca080e7          	jalr	-822(ra) # 80003a66 <iunlockput>
    end_op();
    80004da4:	fffff097          	auipc	ra,0xfffff
    80004da8:	4aa080e7          	jalr	1194(ra) # 8000424e <end_op>
  }
  return -1;
    80004dac:	557d                	li	a0,-1
}
    80004dae:	21813083          	ld	ra,536(sp)
    80004db2:	21013403          	ld	s0,528(sp)
    80004db6:	20813483          	ld	s1,520(sp)
    80004dba:	20013903          	ld	s2,512(sp)
    80004dbe:	79fe                	ld	s3,504(sp)
    80004dc0:	7a5e                	ld	s4,496(sp)
    80004dc2:	7abe                	ld	s5,488(sp)
    80004dc4:	7b1e                	ld	s6,480(sp)
    80004dc6:	6bfe                	ld	s7,472(sp)
    80004dc8:	6c5e                	ld	s8,464(sp)
    80004dca:	6cbe                	ld	s9,456(sp)
    80004dcc:	6d1e                	ld	s10,448(sp)
    80004dce:	7dfa                	ld	s11,440(sp)
    80004dd0:	22010113          	addi	sp,sp,544
    80004dd4:	8082                	ret
    end_op();
    80004dd6:	fffff097          	auipc	ra,0xfffff
    80004dda:	478080e7          	jalr	1144(ra) # 8000424e <end_op>
    return -1;
    80004dde:	557d                	li	a0,-1
    80004de0:	b7f9                	j	80004dae <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004de2:	8526                	mv	a0,s1
    80004de4:	ffffd097          	auipc	ra,0xffffd
    80004de8:	c8c080e7          	jalr	-884(ra) # 80001a70 <proc_pagetable>
    80004dec:	8b2a                	mv	s6,a0
    80004dee:	d555                	beqz	a0,80004d9a <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004df0:	e7042783          	lw	a5,-400(s0)
    80004df4:	e8845703          	lhu	a4,-376(s0)
    80004df8:	c735                	beqz	a4,80004e64 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004dfa:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004dfc:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004e00:	6a05                	lui	s4,0x1
    80004e02:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004e06:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004e0a:	6d85                	lui	s11,0x1
    80004e0c:	7d7d                	lui	s10,0xfffff
    80004e0e:	a491                	j	80005052 <exec+0x340>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004e10:	00004517          	auipc	a0,0x4
    80004e14:	96850513          	addi	a0,a0,-1688 # 80008778 <syscalls+0x290>
    80004e18:	ffffb097          	auipc	ra,0xffffb
    80004e1c:	728080e7          	jalr	1832(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e20:	874a                	mv	a4,s2
    80004e22:	009c86bb          	addw	a3,s9,s1
    80004e26:	4581                	li	a1,0
    80004e28:	8556                	mv	a0,s5
    80004e2a:	fffff097          	auipc	ra,0xfffff
    80004e2e:	c8e080e7          	jalr	-882(ra) # 80003ab8 <readi>
    80004e32:	2501                	sext.w	a0,a0
    80004e34:	1aa91c63          	bne	s2,a0,80004fec <exec+0x2da>
  for(i = 0; i < sz; i += PGSIZE){
    80004e38:	009d84bb          	addw	s1,s11,s1
    80004e3c:	013d09bb          	addw	s3,s10,s3
    80004e40:	1f74f963          	bgeu	s1,s7,80005032 <exec+0x320>
    pa = walkaddr(pagetable, va + i);
    80004e44:	02049593          	slli	a1,s1,0x20
    80004e48:	9181                	srli	a1,a1,0x20
    80004e4a:	95e2                	add	a1,a1,s8
    80004e4c:	855a                	mv	a0,s6
    80004e4e:	ffffc097          	auipc	ra,0xffffc
    80004e52:	20e080e7          	jalr	526(ra) # 8000105c <walkaddr>
    80004e56:	862a                	mv	a2,a0
    if(pa == 0)
    80004e58:	dd45                	beqz	a0,80004e10 <exec+0xfe>
      n = PGSIZE;
    80004e5a:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004e5c:	fd49f2e3          	bgeu	s3,s4,80004e20 <exec+0x10e>
      n = sz - i;
    80004e60:	894e                	mv	s2,s3
    80004e62:	bf7d                	j	80004e20 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e64:	4901                	li	s2,0
  iunlockput(ip);
    80004e66:	8556                	mv	a0,s5
    80004e68:	fffff097          	auipc	ra,0xfffff
    80004e6c:	bfe080e7          	jalr	-1026(ra) # 80003a66 <iunlockput>
  end_op();
    80004e70:	fffff097          	auipc	ra,0xfffff
    80004e74:	3de080e7          	jalr	990(ra) # 8000424e <end_op>
  p = myproc();
    80004e78:	ffffd097          	auipc	ra,0xffffd
    80004e7c:	b34080e7          	jalr	-1228(ra) # 800019ac <myproc>
    80004e80:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004e82:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e86:	6785                	lui	a5,0x1
    80004e88:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80004e8a:	97ca                	add	a5,a5,s2
    80004e8c:	777d                	lui	a4,0xfffff
    80004e8e:	8ff9                	and	a5,a5,a4
    80004e90:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e94:	4691                	li	a3,4
    80004e96:	6609                	lui	a2,0x2
    80004e98:	963e                	add	a2,a2,a5
    80004e9a:	85be                	mv	a1,a5
    80004e9c:	855a                	mv	a0,s6
    80004e9e:	ffffc097          	auipc	ra,0xffffc
    80004ea2:	572080e7          	jalr	1394(ra) # 80001410 <uvmalloc>
    80004ea6:	8c2a                	mv	s8,a0
  ip = 0;
    80004ea8:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004eaa:	14050163          	beqz	a0,80004fec <exec+0x2da>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004eae:	75f9                	lui	a1,0xffffe
    80004eb0:	95aa                	add	a1,a1,a0
    80004eb2:	855a                	mv	a0,s6
    80004eb4:	ffffc097          	auipc	ra,0xffffc
    80004eb8:	786080e7          	jalr	1926(ra) # 8000163a <uvmclear>
  stackbase = sp - PGSIZE;
    80004ebc:	7afd                	lui	s5,0xfffff
    80004ebe:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004ec0:	df043783          	ld	a5,-528(s0)
    80004ec4:	6388                	ld	a0,0(a5)
    80004ec6:	c925                	beqz	a0,80004f36 <exec+0x224>
    80004ec8:	e9040993          	addi	s3,s0,-368
    80004ecc:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004ed0:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004ed2:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004ed4:	ffffc097          	auipc	ra,0xffffc
    80004ed8:	f7a080e7          	jalr	-134(ra) # 80000e4e <strlen>
    80004edc:	0015079b          	addiw	a5,a0,1
    80004ee0:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004ee4:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004ee8:	13596963          	bltu	s2,s5,8000501a <exec+0x308>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004eec:	df043d83          	ld	s11,-528(s0)
    80004ef0:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004ef4:	8552                	mv	a0,s4
    80004ef6:	ffffc097          	auipc	ra,0xffffc
    80004efa:	f58080e7          	jalr	-168(ra) # 80000e4e <strlen>
    80004efe:	0015069b          	addiw	a3,a0,1
    80004f02:	8652                	mv	a2,s4
    80004f04:	85ca                	mv	a1,s2
    80004f06:	855a                	mv	a0,s6
    80004f08:	ffffc097          	auipc	ra,0xffffc
    80004f0c:	764080e7          	jalr	1892(ra) # 8000166c <copyout>
    80004f10:	10054963          	bltz	a0,80005022 <exec+0x310>
    ustack[argc] = sp;
    80004f14:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f18:	0485                	addi	s1,s1,1
    80004f1a:	008d8793          	addi	a5,s11,8
    80004f1e:	def43823          	sd	a5,-528(s0)
    80004f22:	008db503          	ld	a0,8(s11)
    80004f26:	c911                	beqz	a0,80004f3a <exec+0x228>
    if(argc >= MAXARG)
    80004f28:	09a1                	addi	s3,s3,8
    80004f2a:	fb3c95e3          	bne	s9,s3,80004ed4 <exec+0x1c2>
  sz = sz1;
    80004f2e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f32:	4a81                	li	s5,0
    80004f34:	a865                	j	80004fec <exec+0x2da>
  sp = sz;
    80004f36:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004f38:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f3a:	00349793          	slli	a5,s1,0x3
    80004f3e:	f9078793          	addi	a5,a5,-112
    80004f42:	97a2                	add	a5,a5,s0
    80004f44:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004f48:	00148693          	addi	a3,s1,1
    80004f4c:	068e                	slli	a3,a3,0x3
    80004f4e:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f52:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f56:	01597663          	bgeu	s2,s5,80004f62 <exec+0x250>
  sz = sz1;
    80004f5a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f5e:	4a81                	li	s5,0
    80004f60:	a071                	j	80004fec <exec+0x2da>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f62:	e9040613          	addi	a2,s0,-368
    80004f66:	85ca                	mv	a1,s2
    80004f68:	855a                	mv	a0,s6
    80004f6a:	ffffc097          	auipc	ra,0xffffc
    80004f6e:	702080e7          	jalr	1794(ra) # 8000166c <copyout>
    80004f72:	0a054c63          	bltz	a0,8000502a <exec+0x318>
  p->trapframe->a1 = sp;
    80004f76:	058bb783          	ld	a5,88(s7)
    80004f7a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f7e:	de843783          	ld	a5,-536(s0)
    80004f82:	0007c703          	lbu	a4,0(a5)
    80004f86:	cf11                	beqz	a4,80004fa2 <exec+0x290>
    80004f88:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f8a:	02f00693          	li	a3,47
    80004f8e:	a039                	j	80004f9c <exec+0x28a>
      last = s+1;
    80004f90:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004f94:	0785                	addi	a5,a5,1
    80004f96:	fff7c703          	lbu	a4,-1(a5)
    80004f9a:	c701                	beqz	a4,80004fa2 <exec+0x290>
    if(*s == '/')
    80004f9c:	fed71ce3          	bne	a4,a3,80004f94 <exec+0x282>
    80004fa0:	bfc5                	j	80004f90 <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    80004fa2:	4641                	li	a2,16
    80004fa4:	de843583          	ld	a1,-536(s0)
    80004fa8:	158b8513          	addi	a0,s7,344
    80004fac:	ffffc097          	auipc	ra,0xffffc
    80004fb0:	e70080e7          	jalr	-400(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    80004fb4:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004fb8:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004fbc:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004fc0:	058bb783          	ld	a5,88(s7)
    80004fc4:	e6843703          	ld	a4,-408(s0)
    80004fc8:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004fca:	058bb783          	ld	a5,88(s7)
    80004fce:	0327b823          	sd	s2,48(a5)
  p->priority =2;
    80004fd2:	4789                	li	a5,2
    80004fd4:	16fba423          	sw	a5,360(s7)
  proc_freepagetable(oldpagetable, oldsz);
    80004fd8:	85ea                	mv	a1,s10
    80004fda:	ffffd097          	auipc	ra,0xffffd
    80004fde:	b32080e7          	jalr	-1230(ra) # 80001b0c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004fe2:	0004851b          	sext.w	a0,s1
    80004fe6:	b3e1                	j	80004dae <exec+0x9c>
    80004fe8:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004fec:	df843583          	ld	a1,-520(s0)
    80004ff0:	855a                	mv	a0,s6
    80004ff2:	ffffd097          	auipc	ra,0xffffd
    80004ff6:	b1a080e7          	jalr	-1254(ra) # 80001b0c <proc_freepagetable>
  if(ip){
    80004ffa:	da0a90e3          	bnez	s5,80004d9a <exec+0x88>
  return -1;
    80004ffe:	557d                	li	a0,-1
    80005000:	b37d                	j	80004dae <exec+0x9c>
    80005002:	df243c23          	sd	s2,-520(s0)
    80005006:	b7dd                	j	80004fec <exec+0x2da>
    80005008:	df243c23          	sd	s2,-520(s0)
    8000500c:	b7c5                	j	80004fec <exec+0x2da>
    8000500e:	df243c23          	sd	s2,-520(s0)
    80005012:	bfe9                	j	80004fec <exec+0x2da>
    80005014:	df243c23          	sd	s2,-520(s0)
    80005018:	bfd1                	j	80004fec <exec+0x2da>
  sz = sz1;
    8000501a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000501e:	4a81                	li	s5,0
    80005020:	b7f1                	j	80004fec <exec+0x2da>
  sz = sz1;
    80005022:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005026:	4a81                	li	s5,0
    80005028:	b7d1                	j	80004fec <exec+0x2da>
  sz = sz1;
    8000502a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000502e:	4a81                	li	s5,0
    80005030:	bf75                	j	80004fec <exec+0x2da>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005032:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005036:	e0843783          	ld	a5,-504(s0)
    8000503a:	0017869b          	addiw	a3,a5,1
    8000503e:	e0d43423          	sd	a3,-504(s0)
    80005042:	e0043783          	ld	a5,-512(s0)
    80005046:	0387879b          	addiw	a5,a5,56
    8000504a:	e8845703          	lhu	a4,-376(s0)
    8000504e:	e0e6dce3          	bge	a3,a4,80004e66 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005052:	2781                	sext.w	a5,a5
    80005054:	e0f43023          	sd	a5,-512(s0)
    80005058:	03800713          	li	a4,56
    8000505c:	86be                	mv	a3,a5
    8000505e:	e1840613          	addi	a2,s0,-488
    80005062:	4581                	li	a1,0
    80005064:	8556                	mv	a0,s5
    80005066:	fffff097          	auipc	ra,0xfffff
    8000506a:	a52080e7          	jalr	-1454(ra) # 80003ab8 <readi>
    8000506e:	03800793          	li	a5,56
    80005072:	f6f51be3          	bne	a0,a5,80004fe8 <exec+0x2d6>
    if(ph.type != ELF_PROG_LOAD)
    80005076:	e1842783          	lw	a5,-488(s0)
    8000507a:	4705                	li	a4,1
    8000507c:	fae79de3          	bne	a5,a4,80005036 <exec+0x324>
    if(ph.memsz < ph.filesz)
    80005080:	e4043483          	ld	s1,-448(s0)
    80005084:	e3843783          	ld	a5,-456(s0)
    80005088:	f6f4ede3          	bltu	s1,a5,80005002 <exec+0x2f0>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000508c:	e2843783          	ld	a5,-472(s0)
    80005090:	94be                	add	s1,s1,a5
    80005092:	f6f4ebe3          	bltu	s1,a5,80005008 <exec+0x2f6>
    if(ph.vaddr % PGSIZE != 0)
    80005096:	de043703          	ld	a4,-544(s0)
    8000509a:	8ff9                	and	a5,a5,a4
    8000509c:	fbad                	bnez	a5,8000500e <exec+0x2fc>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000509e:	e1c42503          	lw	a0,-484(s0)
    800050a2:	00000097          	auipc	ra,0x0
    800050a6:	c56080e7          	jalr	-938(ra) # 80004cf8 <flags2perm>
    800050aa:	86aa                	mv	a3,a0
    800050ac:	8626                	mv	a2,s1
    800050ae:	85ca                	mv	a1,s2
    800050b0:	855a                	mv	a0,s6
    800050b2:	ffffc097          	auipc	ra,0xffffc
    800050b6:	35e080e7          	jalr	862(ra) # 80001410 <uvmalloc>
    800050ba:	dea43c23          	sd	a0,-520(s0)
    800050be:	d939                	beqz	a0,80005014 <exec+0x302>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800050c0:	e2843c03          	ld	s8,-472(s0)
    800050c4:	e2042c83          	lw	s9,-480(s0)
    800050c8:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800050cc:	f60b83e3          	beqz	s7,80005032 <exec+0x320>
    800050d0:	89de                	mv	s3,s7
    800050d2:	4481                	li	s1,0
    800050d4:	bb85                	j	80004e44 <exec+0x132>

00000000800050d6 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800050d6:	7179                	addi	sp,sp,-48
    800050d8:	f406                	sd	ra,40(sp)
    800050da:	f022                	sd	s0,32(sp)
    800050dc:	ec26                	sd	s1,24(sp)
    800050de:	e84a                	sd	s2,16(sp)
    800050e0:	1800                	addi	s0,sp,48
    800050e2:	892e                	mv	s2,a1
    800050e4:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800050e6:	fdc40593          	addi	a1,s0,-36
    800050ea:	ffffe097          	auipc	ra,0xffffe
    800050ee:	b4c080e7          	jalr	-1204(ra) # 80002c36 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800050f2:	fdc42703          	lw	a4,-36(s0)
    800050f6:	47bd                	li	a5,15
    800050f8:	02e7eb63          	bltu	a5,a4,8000512e <argfd+0x58>
    800050fc:	ffffd097          	auipc	ra,0xffffd
    80005100:	8b0080e7          	jalr	-1872(ra) # 800019ac <myproc>
    80005104:	fdc42703          	lw	a4,-36(s0)
    80005108:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffdd00a>
    8000510c:	078e                	slli	a5,a5,0x3
    8000510e:	953e                	add	a0,a0,a5
    80005110:	611c                	ld	a5,0(a0)
    80005112:	c385                	beqz	a5,80005132 <argfd+0x5c>
    return -1;
  if(pfd)
    80005114:	00090463          	beqz	s2,8000511c <argfd+0x46>
    *pfd = fd;
    80005118:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000511c:	4501                	li	a0,0
  if(pf)
    8000511e:	c091                	beqz	s1,80005122 <argfd+0x4c>
    *pf = f;
    80005120:	e09c                	sd	a5,0(s1)
}
    80005122:	70a2                	ld	ra,40(sp)
    80005124:	7402                	ld	s0,32(sp)
    80005126:	64e2                	ld	s1,24(sp)
    80005128:	6942                	ld	s2,16(sp)
    8000512a:	6145                	addi	sp,sp,48
    8000512c:	8082                	ret
    return -1;
    8000512e:	557d                	li	a0,-1
    80005130:	bfcd                	j	80005122 <argfd+0x4c>
    80005132:	557d                	li	a0,-1
    80005134:	b7fd                	j	80005122 <argfd+0x4c>

0000000080005136 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005136:	1101                	addi	sp,sp,-32
    80005138:	ec06                	sd	ra,24(sp)
    8000513a:	e822                	sd	s0,16(sp)
    8000513c:	e426                	sd	s1,8(sp)
    8000513e:	1000                	addi	s0,sp,32
    80005140:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005142:	ffffd097          	auipc	ra,0xffffd
    80005146:	86a080e7          	jalr	-1942(ra) # 800019ac <myproc>
    8000514a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000514c:	0d050793          	addi	a5,a0,208
    80005150:	4501                	li	a0,0
    80005152:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005154:	6398                	ld	a4,0(a5)
    80005156:	cb19                	beqz	a4,8000516c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005158:	2505                	addiw	a0,a0,1
    8000515a:	07a1                	addi	a5,a5,8
    8000515c:	fed51ce3          	bne	a0,a3,80005154 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005160:	557d                	li	a0,-1
}
    80005162:	60e2                	ld	ra,24(sp)
    80005164:	6442                	ld	s0,16(sp)
    80005166:	64a2                	ld	s1,8(sp)
    80005168:	6105                	addi	sp,sp,32
    8000516a:	8082                	ret
      p->ofile[fd] = f;
    8000516c:	01a50793          	addi	a5,a0,26
    80005170:	078e                	slli	a5,a5,0x3
    80005172:	963e                	add	a2,a2,a5
    80005174:	e204                	sd	s1,0(a2)
      return fd;
    80005176:	b7f5                	j	80005162 <fdalloc+0x2c>

0000000080005178 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005178:	715d                	addi	sp,sp,-80
    8000517a:	e486                	sd	ra,72(sp)
    8000517c:	e0a2                	sd	s0,64(sp)
    8000517e:	fc26                	sd	s1,56(sp)
    80005180:	f84a                	sd	s2,48(sp)
    80005182:	f44e                	sd	s3,40(sp)
    80005184:	f052                	sd	s4,32(sp)
    80005186:	ec56                	sd	s5,24(sp)
    80005188:	e85a                	sd	s6,16(sp)
    8000518a:	0880                	addi	s0,sp,80
    8000518c:	8b2e                	mv	s6,a1
    8000518e:	89b2                	mv	s3,a2
    80005190:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005192:	fb040593          	addi	a1,s0,-80
    80005196:	fffff097          	auipc	ra,0xfffff
    8000519a:	e38080e7          	jalr	-456(ra) # 80003fce <nameiparent>
    8000519e:	84aa                	mv	s1,a0
    800051a0:	14050f63          	beqz	a0,800052fe <create+0x186>
    return 0;

  ilock(dp);
    800051a4:	ffffe097          	auipc	ra,0xffffe
    800051a8:	660080e7          	jalr	1632(ra) # 80003804 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800051ac:	4601                	li	a2,0
    800051ae:	fb040593          	addi	a1,s0,-80
    800051b2:	8526                	mv	a0,s1
    800051b4:	fffff097          	auipc	ra,0xfffff
    800051b8:	b34080e7          	jalr	-1228(ra) # 80003ce8 <dirlookup>
    800051bc:	8aaa                	mv	s5,a0
    800051be:	c931                	beqz	a0,80005212 <create+0x9a>
    iunlockput(dp);
    800051c0:	8526                	mv	a0,s1
    800051c2:	fffff097          	auipc	ra,0xfffff
    800051c6:	8a4080e7          	jalr	-1884(ra) # 80003a66 <iunlockput>
    ilock(ip);
    800051ca:	8556                	mv	a0,s5
    800051cc:	ffffe097          	auipc	ra,0xffffe
    800051d0:	638080e7          	jalr	1592(ra) # 80003804 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800051d4:	000b059b          	sext.w	a1,s6
    800051d8:	4789                	li	a5,2
    800051da:	02f59563          	bne	a1,a5,80005204 <create+0x8c>
    800051de:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdd034>
    800051e2:	37f9                	addiw	a5,a5,-2
    800051e4:	17c2                	slli	a5,a5,0x30
    800051e6:	93c1                	srli	a5,a5,0x30
    800051e8:	4705                	li	a4,1
    800051ea:	00f76d63          	bltu	a4,a5,80005204 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800051ee:	8556                	mv	a0,s5
    800051f0:	60a6                	ld	ra,72(sp)
    800051f2:	6406                	ld	s0,64(sp)
    800051f4:	74e2                	ld	s1,56(sp)
    800051f6:	7942                	ld	s2,48(sp)
    800051f8:	79a2                	ld	s3,40(sp)
    800051fa:	7a02                	ld	s4,32(sp)
    800051fc:	6ae2                	ld	s5,24(sp)
    800051fe:	6b42                	ld	s6,16(sp)
    80005200:	6161                	addi	sp,sp,80
    80005202:	8082                	ret
    iunlockput(ip);
    80005204:	8556                	mv	a0,s5
    80005206:	fffff097          	auipc	ra,0xfffff
    8000520a:	860080e7          	jalr	-1952(ra) # 80003a66 <iunlockput>
    return 0;
    8000520e:	4a81                	li	s5,0
    80005210:	bff9                	j	800051ee <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005212:	85da                	mv	a1,s6
    80005214:	4088                	lw	a0,0(s1)
    80005216:	ffffe097          	auipc	ra,0xffffe
    8000521a:	450080e7          	jalr	1104(ra) # 80003666 <ialloc>
    8000521e:	8a2a                	mv	s4,a0
    80005220:	c539                	beqz	a0,8000526e <create+0xf6>
  ilock(ip);
    80005222:	ffffe097          	auipc	ra,0xffffe
    80005226:	5e2080e7          	jalr	1506(ra) # 80003804 <ilock>
  ip->major = major;
    8000522a:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    8000522e:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005232:	4905                	li	s2,1
    80005234:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005238:	8552                	mv	a0,s4
    8000523a:	ffffe097          	auipc	ra,0xffffe
    8000523e:	4fe080e7          	jalr	1278(ra) # 80003738 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005242:	000b059b          	sext.w	a1,s6
    80005246:	03258b63          	beq	a1,s2,8000527c <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    8000524a:	004a2603          	lw	a2,4(s4)
    8000524e:	fb040593          	addi	a1,s0,-80
    80005252:	8526                	mv	a0,s1
    80005254:	fffff097          	auipc	ra,0xfffff
    80005258:	caa080e7          	jalr	-854(ra) # 80003efe <dirlink>
    8000525c:	06054f63          	bltz	a0,800052da <create+0x162>
  iunlockput(dp);
    80005260:	8526                	mv	a0,s1
    80005262:	fffff097          	auipc	ra,0xfffff
    80005266:	804080e7          	jalr	-2044(ra) # 80003a66 <iunlockput>
  return ip;
    8000526a:	8ad2                	mv	s5,s4
    8000526c:	b749                	j	800051ee <create+0x76>
    iunlockput(dp);
    8000526e:	8526                	mv	a0,s1
    80005270:	ffffe097          	auipc	ra,0xffffe
    80005274:	7f6080e7          	jalr	2038(ra) # 80003a66 <iunlockput>
    return 0;
    80005278:	8ad2                	mv	s5,s4
    8000527a:	bf95                	j	800051ee <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000527c:	004a2603          	lw	a2,4(s4)
    80005280:	00003597          	auipc	a1,0x3
    80005284:	51858593          	addi	a1,a1,1304 # 80008798 <syscalls+0x2b0>
    80005288:	8552                	mv	a0,s4
    8000528a:	fffff097          	auipc	ra,0xfffff
    8000528e:	c74080e7          	jalr	-908(ra) # 80003efe <dirlink>
    80005292:	04054463          	bltz	a0,800052da <create+0x162>
    80005296:	40d0                	lw	a2,4(s1)
    80005298:	00003597          	auipc	a1,0x3
    8000529c:	50858593          	addi	a1,a1,1288 # 800087a0 <syscalls+0x2b8>
    800052a0:	8552                	mv	a0,s4
    800052a2:	fffff097          	auipc	ra,0xfffff
    800052a6:	c5c080e7          	jalr	-932(ra) # 80003efe <dirlink>
    800052aa:	02054863          	bltz	a0,800052da <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    800052ae:	004a2603          	lw	a2,4(s4)
    800052b2:	fb040593          	addi	a1,s0,-80
    800052b6:	8526                	mv	a0,s1
    800052b8:	fffff097          	auipc	ra,0xfffff
    800052bc:	c46080e7          	jalr	-954(ra) # 80003efe <dirlink>
    800052c0:	00054d63          	bltz	a0,800052da <create+0x162>
    dp->nlink++;  // for ".."
    800052c4:	04a4d783          	lhu	a5,74(s1)
    800052c8:	2785                	addiw	a5,a5,1
    800052ca:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800052ce:	8526                	mv	a0,s1
    800052d0:	ffffe097          	auipc	ra,0xffffe
    800052d4:	468080e7          	jalr	1128(ra) # 80003738 <iupdate>
    800052d8:	b761                	j	80005260 <create+0xe8>
  ip->nlink = 0;
    800052da:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800052de:	8552                	mv	a0,s4
    800052e0:	ffffe097          	auipc	ra,0xffffe
    800052e4:	458080e7          	jalr	1112(ra) # 80003738 <iupdate>
  iunlockput(ip);
    800052e8:	8552                	mv	a0,s4
    800052ea:	ffffe097          	auipc	ra,0xffffe
    800052ee:	77c080e7          	jalr	1916(ra) # 80003a66 <iunlockput>
  iunlockput(dp);
    800052f2:	8526                	mv	a0,s1
    800052f4:	ffffe097          	auipc	ra,0xffffe
    800052f8:	772080e7          	jalr	1906(ra) # 80003a66 <iunlockput>
  return 0;
    800052fc:	bdcd                	j	800051ee <create+0x76>
    return 0;
    800052fe:	8aaa                	mv	s5,a0
    80005300:	b5fd                	j	800051ee <create+0x76>

0000000080005302 <sys_dup>:
{
    80005302:	7179                	addi	sp,sp,-48
    80005304:	f406                	sd	ra,40(sp)
    80005306:	f022                	sd	s0,32(sp)
    80005308:	ec26                	sd	s1,24(sp)
    8000530a:	e84a                	sd	s2,16(sp)
    8000530c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000530e:	fd840613          	addi	a2,s0,-40
    80005312:	4581                	li	a1,0
    80005314:	4501                	li	a0,0
    80005316:	00000097          	auipc	ra,0x0
    8000531a:	dc0080e7          	jalr	-576(ra) # 800050d6 <argfd>
    return -1;
    8000531e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005320:	02054363          	bltz	a0,80005346 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005324:	fd843903          	ld	s2,-40(s0)
    80005328:	854a                	mv	a0,s2
    8000532a:	00000097          	auipc	ra,0x0
    8000532e:	e0c080e7          	jalr	-500(ra) # 80005136 <fdalloc>
    80005332:	84aa                	mv	s1,a0
    return -1;
    80005334:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005336:	00054863          	bltz	a0,80005346 <sys_dup+0x44>
  filedup(f);
    8000533a:	854a                	mv	a0,s2
    8000533c:	fffff097          	auipc	ra,0xfffff
    80005340:	30a080e7          	jalr	778(ra) # 80004646 <filedup>
  return fd;
    80005344:	87a6                	mv	a5,s1
}
    80005346:	853e                	mv	a0,a5
    80005348:	70a2                	ld	ra,40(sp)
    8000534a:	7402                	ld	s0,32(sp)
    8000534c:	64e2                	ld	s1,24(sp)
    8000534e:	6942                	ld	s2,16(sp)
    80005350:	6145                	addi	sp,sp,48
    80005352:	8082                	ret

0000000080005354 <sys_read>:
{
    80005354:	7179                	addi	sp,sp,-48
    80005356:	f406                	sd	ra,40(sp)
    80005358:	f022                	sd	s0,32(sp)
    8000535a:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000535c:	fd840593          	addi	a1,s0,-40
    80005360:	4505                	li	a0,1
    80005362:	ffffe097          	auipc	ra,0xffffe
    80005366:	8f4080e7          	jalr	-1804(ra) # 80002c56 <argaddr>
  argint(2, &n);
    8000536a:	fe440593          	addi	a1,s0,-28
    8000536e:	4509                	li	a0,2
    80005370:	ffffe097          	auipc	ra,0xffffe
    80005374:	8c6080e7          	jalr	-1850(ra) # 80002c36 <argint>
  if(argfd(0, 0, &f) < 0)
    80005378:	fe840613          	addi	a2,s0,-24
    8000537c:	4581                	li	a1,0
    8000537e:	4501                	li	a0,0
    80005380:	00000097          	auipc	ra,0x0
    80005384:	d56080e7          	jalr	-682(ra) # 800050d6 <argfd>
    80005388:	87aa                	mv	a5,a0
    return -1;
    8000538a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000538c:	0007cc63          	bltz	a5,800053a4 <sys_read+0x50>
  return fileread(f, p, n);
    80005390:	fe442603          	lw	a2,-28(s0)
    80005394:	fd843583          	ld	a1,-40(s0)
    80005398:	fe843503          	ld	a0,-24(s0)
    8000539c:	fffff097          	auipc	ra,0xfffff
    800053a0:	436080e7          	jalr	1078(ra) # 800047d2 <fileread>
}
    800053a4:	70a2                	ld	ra,40(sp)
    800053a6:	7402                	ld	s0,32(sp)
    800053a8:	6145                	addi	sp,sp,48
    800053aa:	8082                	ret

00000000800053ac <sys_write>:
{
    800053ac:	7179                	addi	sp,sp,-48
    800053ae:	f406                	sd	ra,40(sp)
    800053b0:	f022                	sd	s0,32(sp)
    800053b2:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800053b4:	fd840593          	addi	a1,s0,-40
    800053b8:	4505                	li	a0,1
    800053ba:	ffffe097          	auipc	ra,0xffffe
    800053be:	89c080e7          	jalr	-1892(ra) # 80002c56 <argaddr>
  argint(2, &n);
    800053c2:	fe440593          	addi	a1,s0,-28
    800053c6:	4509                	li	a0,2
    800053c8:	ffffe097          	auipc	ra,0xffffe
    800053cc:	86e080e7          	jalr	-1938(ra) # 80002c36 <argint>
  if(argfd(0, 0, &f) < 0)
    800053d0:	fe840613          	addi	a2,s0,-24
    800053d4:	4581                	li	a1,0
    800053d6:	4501                	li	a0,0
    800053d8:	00000097          	auipc	ra,0x0
    800053dc:	cfe080e7          	jalr	-770(ra) # 800050d6 <argfd>
    800053e0:	87aa                	mv	a5,a0
    return -1;
    800053e2:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800053e4:	0007cc63          	bltz	a5,800053fc <sys_write+0x50>
  return filewrite(f, p, n);
    800053e8:	fe442603          	lw	a2,-28(s0)
    800053ec:	fd843583          	ld	a1,-40(s0)
    800053f0:	fe843503          	ld	a0,-24(s0)
    800053f4:	fffff097          	auipc	ra,0xfffff
    800053f8:	4a0080e7          	jalr	1184(ra) # 80004894 <filewrite>
}
    800053fc:	70a2                	ld	ra,40(sp)
    800053fe:	7402                	ld	s0,32(sp)
    80005400:	6145                	addi	sp,sp,48
    80005402:	8082                	ret

0000000080005404 <sys_close>:
{
    80005404:	1101                	addi	sp,sp,-32
    80005406:	ec06                	sd	ra,24(sp)
    80005408:	e822                	sd	s0,16(sp)
    8000540a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000540c:	fe040613          	addi	a2,s0,-32
    80005410:	fec40593          	addi	a1,s0,-20
    80005414:	4501                	li	a0,0
    80005416:	00000097          	auipc	ra,0x0
    8000541a:	cc0080e7          	jalr	-832(ra) # 800050d6 <argfd>
    return -1;
    8000541e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005420:	02054463          	bltz	a0,80005448 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005424:	ffffc097          	auipc	ra,0xffffc
    80005428:	588080e7          	jalr	1416(ra) # 800019ac <myproc>
    8000542c:	fec42783          	lw	a5,-20(s0)
    80005430:	07e9                	addi	a5,a5,26
    80005432:	078e                	slli	a5,a5,0x3
    80005434:	953e                	add	a0,a0,a5
    80005436:	00053023          	sd	zero,0(a0)
  fileclose(f);
    8000543a:	fe043503          	ld	a0,-32(s0)
    8000543e:	fffff097          	auipc	ra,0xfffff
    80005442:	25a080e7          	jalr	602(ra) # 80004698 <fileclose>
  return 0;
    80005446:	4781                	li	a5,0
}
    80005448:	853e                	mv	a0,a5
    8000544a:	60e2                	ld	ra,24(sp)
    8000544c:	6442                	ld	s0,16(sp)
    8000544e:	6105                	addi	sp,sp,32
    80005450:	8082                	ret

0000000080005452 <sys_fstat>:
{
    80005452:	1101                	addi	sp,sp,-32
    80005454:	ec06                	sd	ra,24(sp)
    80005456:	e822                	sd	s0,16(sp)
    80005458:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    8000545a:	fe040593          	addi	a1,s0,-32
    8000545e:	4505                	li	a0,1
    80005460:	ffffd097          	auipc	ra,0xffffd
    80005464:	7f6080e7          	jalr	2038(ra) # 80002c56 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005468:	fe840613          	addi	a2,s0,-24
    8000546c:	4581                	li	a1,0
    8000546e:	4501                	li	a0,0
    80005470:	00000097          	auipc	ra,0x0
    80005474:	c66080e7          	jalr	-922(ra) # 800050d6 <argfd>
    80005478:	87aa                	mv	a5,a0
    return -1;
    8000547a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000547c:	0007ca63          	bltz	a5,80005490 <sys_fstat+0x3e>
  return filestat(f, st);
    80005480:	fe043583          	ld	a1,-32(s0)
    80005484:	fe843503          	ld	a0,-24(s0)
    80005488:	fffff097          	auipc	ra,0xfffff
    8000548c:	2d8080e7          	jalr	728(ra) # 80004760 <filestat>
}
    80005490:	60e2                	ld	ra,24(sp)
    80005492:	6442                	ld	s0,16(sp)
    80005494:	6105                	addi	sp,sp,32
    80005496:	8082                	ret

0000000080005498 <sys_link>:
{
    80005498:	7169                	addi	sp,sp,-304
    8000549a:	f606                	sd	ra,296(sp)
    8000549c:	f222                	sd	s0,288(sp)
    8000549e:	ee26                	sd	s1,280(sp)
    800054a0:	ea4a                	sd	s2,272(sp)
    800054a2:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054a4:	08000613          	li	a2,128
    800054a8:	ed040593          	addi	a1,s0,-304
    800054ac:	4501                	li	a0,0
    800054ae:	ffffd097          	auipc	ra,0xffffd
    800054b2:	7c8080e7          	jalr	1992(ra) # 80002c76 <argstr>
    return -1;
    800054b6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054b8:	10054e63          	bltz	a0,800055d4 <sys_link+0x13c>
    800054bc:	08000613          	li	a2,128
    800054c0:	f5040593          	addi	a1,s0,-176
    800054c4:	4505                	li	a0,1
    800054c6:	ffffd097          	auipc	ra,0xffffd
    800054ca:	7b0080e7          	jalr	1968(ra) # 80002c76 <argstr>
    return -1;
    800054ce:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054d0:	10054263          	bltz	a0,800055d4 <sys_link+0x13c>
  begin_op();
    800054d4:	fffff097          	auipc	ra,0xfffff
    800054d8:	cfc080e7          	jalr	-772(ra) # 800041d0 <begin_op>
  if((ip = namei(old)) == 0){
    800054dc:	ed040513          	addi	a0,s0,-304
    800054e0:	fffff097          	auipc	ra,0xfffff
    800054e4:	ad0080e7          	jalr	-1328(ra) # 80003fb0 <namei>
    800054e8:	84aa                	mv	s1,a0
    800054ea:	c551                	beqz	a0,80005576 <sys_link+0xde>
  ilock(ip);
    800054ec:	ffffe097          	auipc	ra,0xffffe
    800054f0:	318080e7          	jalr	792(ra) # 80003804 <ilock>
  if(ip->type == T_DIR){
    800054f4:	04449703          	lh	a4,68(s1)
    800054f8:	4785                	li	a5,1
    800054fa:	08f70463          	beq	a4,a5,80005582 <sys_link+0xea>
  ip->nlink++;
    800054fe:	04a4d783          	lhu	a5,74(s1)
    80005502:	2785                	addiw	a5,a5,1
    80005504:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005508:	8526                	mv	a0,s1
    8000550a:	ffffe097          	auipc	ra,0xffffe
    8000550e:	22e080e7          	jalr	558(ra) # 80003738 <iupdate>
  iunlock(ip);
    80005512:	8526                	mv	a0,s1
    80005514:	ffffe097          	auipc	ra,0xffffe
    80005518:	3b2080e7          	jalr	946(ra) # 800038c6 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000551c:	fd040593          	addi	a1,s0,-48
    80005520:	f5040513          	addi	a0,s0,-176
    80005524:	fffff097          	auipc	ra,0xfffff
    80005528:	aaa080e7          	jalr	-1366(ra) # 80003fce <nameiparent>
    8000552c:	892a                	mv	s2,a0
    8000552e:	c935                	beqz	a0,800055a2 <sys_link+0x10a>
  ilock(dp);
    80005530:	ffffe097          	auipc	ra,0xffffe
    80005534:	2d4080e7          	jalr	724(ra) # 80003804 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005538:	00092703          	lw	a4,0(s2)
    8000553c:	409c                	lw	a5,0(s1)
    8000553e:	04f71d63          	bne	a4,a5,80005598 <sys_link+0x100>
    80005542:	40d0                	lw	a2,4(s1)
    80005544:	fd040593          	addi	a1,s0,-48
    80005548:	854a                	mv	a0,s2
    8000554a:	fffff097          	auipc	ra,0xfffff
    8000554e:	9b4080e7          	jalr	-1612(ra) # 80003efe <dirlink>
    80005552:	04054363          	bltz	a0,80005598 <sys_link+0x100>
  iunlockput(dp);
    80005556:	854a                	mv	a0,s2
    80005558:	ffffe097          	auipc	ra,0xffffe
    8000555c:	50e080e7          	jalr	1294(ra) # 80003a66 <iunlockput>
  iput(ip);
    80005560:	8526                	mv	a0,s1
    80005562:	ffffe097          	auipc	ra,0xffffe
    80005566:	45c080e7          	jalr	1116(ra) # 800039be <iput>
  end_op();
    8000556a:	fffff097          	auipc	ra,0xfffff
    8000556e:	ce4080e7          	jalr	-796(ra) # 8000424e <end_op>
  return 0;
    80005572:	4781                	li	a5,0
    80005574:	a085                	j	800055d4 <sys_link+0x13c>
    end_op();
    80005576:	fffff097          	auipc	ra,0xfffff
    8000557a:	cd8080e7          	jalr	-808(ra) # 8000424e <end_op>
    return -1;
    8000557e:	57fd                	li	a5,-1
    80005580:	a891                	j	800055d4 <sys_link+0x13c>
    iunlockput(ip);
    80005582:	8526                	mv	a0,s1
    80005584:	ffffe097          	auipc	ra,0xffffe
    80005588:	4e2080e7          	jalr	1250(ra) # 80003a66 <iunlockput>
    end_op();
    8000558c:	fffff097          	auipc	ra,0xfffff
    80005590:	cc2080e7          	jalr	-830(ra) # 8000424e <end_op>
    return -1;
    80005594:	57fd                	li	a5,-1
    80005596:	a83d                	j	800055d4 <sys_link+0x13c>
    iunlockput(dp);
    80005598:	854a                	mv	a0,s2
    8000559a:	ffffe097          	auipc	ra,0xffffe
    8000559e:	4cc080e7          	jalr	1228(ra) # 80003a66 <iunlockput>
  ilock(ip);
    800055a2:	8526                	mv	a0,s1
    800055a4:	ffffe097          	auipc	ra,0xffffe
    800055a8:	260080e7          	jalr	608(ra) # 80003804 <ilock>
  ip->nlink--;
    800055ac:	04a4d783          	lhu	a5,74(s1)
    800055b0:	37fd                	addiw	a5,a5,-1
    800055b2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055b6:	8526                	mv	a0,s1
    800055b8:	ffffe097          	auipc	ra,0xffffe
    800055bc:	180080e7          	jalr	384(ra) # 80003738 <iupdate>
  iunlockput(ip);
    800055c0:	8526                	mv	a0,s1
    800055c2:	ffffe097          	auipc	ra,0xffffe
    800055c6:	4a4080e7          	jalr	1188(ra) # 80003a66 <iunlockput>
  end_op();
    800055ca:	fffff097          	auipc	ra,0xfffff
    800055ce:	c84080e7          	jalr	-892(ra) # 8000424e <end_op>
  return -1;
    800055d2:	57fd                	li	a5,-1
}
    800055d4:	853e                	mv	a0,a5
    800055d6:	70b2                	ld	ra,296(sp)
    800055d8:	7412                	ld	s0,288(sp)
    800055da:	64f2                	ld	s1,280(sp)
    800055dc:	6952                	ld	s2,272(sp)
    800055de:	6155                	addi	sp,sp,304
    800055e0:	8082                	ret

00000000800055e2 <sys_unlink>:
{
    800055e2:	7151                	addi	sp,sp,-240
    800055e4:	f586                	sd	ra,232(sp)
    800055e6:	f1a2                	sd	s0,224(sp)
    800055e8:	eda6                	sd	s1,216(sp)
    800055ea:	e9ca                	sd	s2,208(sp)
    800055ec:	e5ce                	sd	s3,200(sp)
    800055ee:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800055f0:	08000613          	li	a2,128
    800055f4:	f3040593          	addi	a1,s0,-208
    800055f8:	4501                	li	a0,0
    800055fa:	ffffd097          	auipc	ra,0xffffd
    800055fe:	67c080e7          	jalr	1660(ra) # 80002c76 <argstr>
    80005602:	18054163          	bltz	a0,80005784 <sys_unlink+0x1a2>
  begin_op();
    80005606:	fffff097          	auipc	ra,0xfffff
    8000560a:	bca080e7          	jalr	-1078(ra) # 800041d0 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000560e:	fb040593          	addi	a1,s0,-80
    80005612:	f3040513          	addi	a0,s0,-208
    80005616:	fffff097          	auipc	ra,0xfffff
    8000561a:	9b8080e7          	jalr	-1608(ra) # 80003fce <nameiparent>
    8000561e:	84aa                	mv	s1,a0
    80005620:	c979                	beqz	a0,800056f6 <sys_unlink+0x114>
  ilock(dp);
    80005622:	ffffe097          	auipc	ra,0xffffe
    80005626:	1e2080e7          	jalr	482(ra) # 80003804 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000562a:	00003597          	auipc	a1,0x3
    8000562e:	16e58593          	addi	a1,a1,366 # 80008798 <syscalls+0x2b0>
    80005632:	fb040513          	addi	a0,s0,-80
    80005636:	ffffe097          	auipc	ra,0xffffe
    8000563a:	698080e7          	jalr	1688(ra) # 80003cce <namecmp>
    8000563e:	14050a63          	beqz	a0,80005792 <sys_unlink+0x1b0>
    80005642:	00003597          	auipc	a1,0x3
    80005646:	15e58593          	addi	a1,a1,350 # 800087a0 <syscalls+0x2b8>
    8000564a:	fb040513          	addi	a0,s0,-80
    8000564e:	ffffe097          	auipc	ra,0xffffe
    80005652:	680080e7          	jalr	1664(ra) # 80003cce <namecmp>
    80005656:	12050e63          	beqz	a0,80005792 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000565a:	f2c40613          	addi	a2,s0,-212
    8000565e:	fb040593          	addi	a1,s0,-80
    80005662:	8526                	mv	a0,s1
    80005664:	ffffe097          	auipc	ra,0xffffe
    80005668:	684080e7          	jalr	1668(ra) # 80003ce8 <dirlookup>
    8000566c:	892a                	mv	s2,a0
    8000566e:	12050263          	beqz	a0,80005792 <sys_unlink+0x1b0>
  ilock(ip);
    80005672:	ffffe097          	auipc	ra,0xffffe
    80005676:	192080e7          	jalr	402(ra) # 80003804 <ilock>
  if(ip->nlink < 1)
    8000567a:	04a91783          	lh	a5,74(s2)
    8000567e:	08f05263          	blez	a5,80005702 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005682:	04491703          	lh	a4,68(s2)
    80005686:	4785                	li	a5,1
    80005688:	08f70563          	beq	a4,a5,80005712 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000568c:	4641                	li	a2,16
    8000568e:	4581                	li	a1,0
    80005690:	fc040513          	addi	a0,s0,-64
    80005694:	ffffb097          	auipc	ra,0xffffb
    80005698:	63e080e7          	jalr	1598(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000569c:	4741                	li	a4,16
    8000569e:	f2c42683          	lw	a3,-212(s0)
    800056a2:	fc040613          	addi	a2,s0,-64
    800056a6:	4581                	li	a1,0
    800056a8:	8526                	mv	a0,s1
    800056aa:	ffffe097          	auipc	ra,0xffffe
    800056ae:	506080e7          	jalr	1286(ra) # 80003bb0 <writei>
    800056b2:	47c1                	li	a5,16
    800056b4:	0af51563          	bne	a0,a5,8000575e <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800056b8:	04491703          	lh	a4,68(s2)
    800056bc:	4785                	li	a5,1
    800056be:	0af70863          	beq	a4,a5,8000576e <sys_unlink+0x18c>
  iunlockput(dp);
    800056c2:	8526                	mv	a0,s1
    800056c4:	ffffe097          	auipc	ra,0xffffe
    800056c8:	3a2080e7          	jalr	930(ra) # 80003a66 <iunlockput>
  ip->nlink--;
    800056cc:	04a95783          	lhu	a5,74(s2)
    800056d0:	37fd                	addiw	a5,a5,-1
    800056d2:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800056d6:	854a                	mv	a0,s2
    800056d8:	ffffe097          	auipc	ra,0xffffe
    800056dc:	060080e7          	jalr	96(ra) # 80003738 <iupdate>
  iunlockput(ip);
    800056e0:	854a                	mv	a0,s2
    800056e2:	ffffe097          	auipc	ra,0xffffe
    800056e6:	384080e7          	jalr	900(ra) # 80003a66 <iunlockput>
  end_op();
    800056ea:	fffff097          	auipc	ra,0xfffff
    800056ee:	b64080e7          	jalr	-1180(ra) # 8000424e <end_op>
  return 0;
    800056f2:	4501                	li	a0,0
    800056f4:	a84d                	j	800057a6 <sys_unlink+0x1c4>
    end_op();
    800056f6:	fffff097          	auipc	ra,0xfffff
    800056fa:	b58080e7          	jalr	-1192(ra) # 8000424e <end_op>
    return -1;
    800056fe:	557d                	li	a0,-1
    80005700:	a05d                	j	800057a6 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005702:	00003517          	auipc	a0,0x3
    80005706:	0a650513          	addi	a0,a0,166 # 800087a8 <syscalls+0x2c0>
    8000570a:	ffffb097          	auipc	ra,0xffffb
    8000570e:	e36080e7          	jalr	-458(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005712:	04c92703          	lw	a4,76(s2)
    80005716:	02000793          	li	a5,32
    8000571a:	f6e7f9e3          	bgeu	a5,a4,8000568c <sys_unlink+0xaa>
    8000571e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005722:	4741                	li	a4,16
    80005724:	86ce                	mv	a3,s3
    80005726:	f1840613          	addi	a2,s0,-232
    8000572a:	4581                	li	a1,0
    8000572c:	854a                	mv	a0,s2
    8000572e:	ffffe097          	auipc	ra,0xffffe
    80005732:	38a080e7          	jalr	906(ra) # 80003ab8 <readi>
    80005736:	47c1                	li	a5,16
    80005738:	00f51b63          	bne	a0,a5,8000574e <sys_unlink+0x16c>
    if(de.inum != 0)
    8000573c:	f1845783          	lhu	a5,-232(s0)
    80005740:	e7a1                	bnez	a5,80005788 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005742:	29c1                	addiw	s3,s3,16
    80005744:	04c92783          	lw	a5,76(s2)
    80005748:	fcf9ede3          	bltu	s3,a5,80005722 <sys_unlink+0x140>
    8000574c:	b781                	j	8000568c <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000574e:	00003517          	auipc	a0,0x3
    80005752:	07250513          	addi	a0,a0,114 # 800087c0 <syscalls+0x2d8>
    80005756:	ffffb097          	auipc	ra,0xffffb
    8000575a:	dea080e7          	jalr	-534(ra) # 80000540 <panic>
    panic("unlink: writei");
    8000575e:	00003517          	auipc	a0,0x3
    80005762:	07a50513          	addi	a0,a0,122 # 800087d8 <syscalls+0x2f0>
    80005766:	ffffb097          	auipc	ra,0xffffb
    8000576a:	dda080e7          	jalr	-550(ra) # 80000540 <panic>
    dp->nlink--;
    8000576e:	04a4d783          	lhu	a5,74(s1)
    80005772:	37fd                	addiw	a5,a5,-1
    80005774:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005778:	8526                	mv	a0,s1
    8000577a:	ffffe097          	auipc	ra,0xffffe
    8000577e:	fbe080e7          	jalr	-66(ra) # 80003738 <iupdate>
    80005782:	b781                	j	800056c2 <sys_unlink+0xe0>
    return -1;
    80005784:	557d                	li	a0,-1
    80005786:	a005                	j	800057a6 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005788:	854a                	mv	a0,s2
    8000578a:	ffffe097          	auipc	ra,0xffffe
    8000578e:	2dc080e7          	jalr	732(ra) # 80003a66 <iunlockput>
  iunlockput(dp);
    80005792:	8526                	mv	a0,s1
    80005794:	ffffe097          	auipc	ra,0xffffe
    80005798:	2d2080e7          	jalr	722(ra) # 80003a66 <iunlockput>
  end_op();
    8000579c:	fffff097          	auipc	ra,0xfffff
    800057a0:	ab2080e7          	jalr	-1358(ra) # 8000424e <end_op>
  return -1;
    800057a4:	557d                	li	a0,-1
}
    800057a6:	70ae                	ld	ra,232(sp)
    800057a8:	740e                	ld	s0,224(sp)
    800057aa:	64ee                	ld	s1,216(sp)
    800057ac:	694e                	ld	s2,208(sp)
    800057ae:	69ae                	ld	s3,200(sp)
    800057b0:	616d                	addi	sp,sp,240
    800057b2:	8082                	ret

00000000800057b4 <sys_open>:

uint64
sys_open(void)
{
    800057b4:	7131                	addi	sp,sp,-192
    800057b6:	fd06                	sd	ra,184(sp)
    800057b8:	f922                	sd	s0,176(sp)
    800057ba:	f526                	sd	s1,168(sp)
    800057bc:	f14a                	sd	s2,160(sp)
    800057be:	ed4e                	sd	s3,152(sp)
    800057c0:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800057c2:	f4c40593          	addi	a1,s0,-180
    800057c6:	4505                	li	a0,1
    800057c8:	ffffd097          	auipc	ra,0xffffd
    800057cc:	46e080e7          	jalr	1134(ra) # 80002c36 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800057d0:	08000613          	li	a2,128
    800057d4:	f5040593          	addi	a1,s0,-176
    800057d8:	4501                	li	a0,0
    800057da:	ffffd097          	auipc	ra,0xffffd
    800057de:	49c080e7          	jalr	1180(ra) # 80002c76 <argstr>
    800057e2:	87aa                	mv	a5,a0
    return -1;
    800057e4:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800057e6:	0a07c963          	bltz	a5,80005898 <sys_open+0xe4>

  begin_op();
    800057ea:	fffff097          	auipc	ra,0xfffff
    800057ee:	9e6080e7          	jalr	-1562(ra) # 800041d0 <begin_op>

  if(omode & O_CREATE){
    800057f2:	f4c42783          	lw	a5,-180(s0)
    800057f6:	2007f793          	andi	a5,a5,512
    800057fa:	cfc5                	beqz	a5,800058b2 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800057fc:	4681                	li	a3,0
    800057fe:	4601                	li	a2,0
    80005800:	4589                	li	a1,2
    80005802:	f5040513          	addi	a0,s0,-176
    80005806:	00000097          	auipc	ra,0x0
    8000580a:	972080e7          	jalr	-1678(ra) # 80005178 <create>
    8000580e:	84aa                	mv	s1,a0
    if(ip == 0){
    80005810:	c959                	beqz	a0,800058a6 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005812:	04449703          	lh	a4,68(s1)
    80005816:	478d                	li	a5,3
    80005818:	00f71763          	bne	a4,a5,80005826 <sys_open+0x72>
    8000581c:	0464d703          	lhu	a4,70(s1)
    80005820:	47a5                	li	a5,9
    80005822:	0ce7ed63          	bltu	a5,a4,800058fc <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005826:	fffff097          	auipc	ra,0xfffff
    8000582a:	db6080e7          	jalr	-586(ra) # 800045dc <filealloc>
    8000582e:	89aa                	mv	s3,a0
    80005830:	10050363          	beqz	a0,80005936 <sys_open+0x182>
    80005834:	00000097          	auipc	ra,0x0
    80005838:	902080e7          	jalr	-1790(ra) # 80005136 <fdalloc>
    8000583c:	892a                	mv	s2,a0
    8000583e:	0e054763          	bltz	a0,8000592c <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005842:	04449703          	lh	a4,68(s1)
    80005846:	478d                	li	a5,3
    80005848:	0cf70563          	beq	a4,a5,80005912 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000584c:	4789                	li	a5,2
    8000584e:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005852:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005856:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000585a:	f4c42783          	lw	a5,-180(s0)
    8000585e:	0017c713          	xori	a4,a5,1
    80005862:	8b05                	andi	a4,a4,1
    80005864:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005868:	0037f713          	andi	a4,a5,3
    8000586c:	00e03733          	snez	a4,a4
    80005870:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005874:	4007f793          	andi	a5,a5,1024
    80005878:	c791                	beqz	a5,80005884 <sys_open+0xd0>
    8000587a:	04449703          	lh	a4,68(s1)
    8000587e:	4789                	li	a5,2
    80005880:	0af70063          	beq	a4,a5,80005920 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005884:	8526                	mv	a0,s1
    80005886:	ffffe097          	auipc	ra,0xffffe
    8000588a:	040080e7          	jalr	64(ra) # 800038c6 <iunlock>
  end_op();
    8000588e:	fffff097          	auipc	ra,0xfffff
    80005892:	9c0080e7          	jalr	-1600(ra) # 8000424e <end_op>

  return fd;
    80005896:	854a                	mv	a0,s2
}
    80005898:	70ea                	ld	ra,184(sp)
    8000589a:	744a                	ld	s0,176(sp)
    8000589c:	74aa                	ld	s1,168(sp)
    8000589e:	790a                	ld	s2,160(sp)
    800058a0:	69ea                	ld	s3,152(sp)
    800058a2:	6129                	addi	sp,sp,192
    800058a4:	8082                	ret
      end_op();
    800058a6:	fffff097          	auipc	ra,0xfffff
    800058aa:	9a8080e7          	jalr	-1624(ra) # 8000424e <end_op>
      return -1;
    800058ae:	557d                	li	a0,-1
    800058b0:	b7e5                	j	80005898 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800058b2:	f5040513          	addi	a0,s0,-176
    800058b6:	ffffe097          	auipc	ra,0xffffe
    800058ba:	6fa080e7          	jalr	1786(ra) # 80003fb0 <namei>
    800058be:	84aa                	mv	s1,a0
    800058c0:	c905                	beqz	a0,800058f0 <sys_open+0x13c>
    ilock(ip);
    800058c2:	ffffe097          	auipc	ra,0xffffe
    800058c6:	f42080e7          	jalr	-190(ra) # 80003804 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800058ca:	04449703          	lh	a4,68(s1)
    800058ce:	4785                	li	a5,1
    800058d0:	f4f711e3          	bne	a4,a5,80005812 <sys_open+0x5e>
    800058d4:	f4c42783          	lw	a5,-180(s0)
    800058d8:	d7b9                	beqz	a5,80005826 <sys_open+0x72>
      iunlockput(ip);
    800058da:	8526                	mv	a0,s1
    800058dc:	ffffe097          	auipc	ra,0xffffe
    800058e0:	18a080e7          	jalr	394(ra) # 80003a66 <iunlockput>
      end_op();
    800058e4:	fffff097          	auipc	ra,0xfffff
    800058e8:	96a080e7          	jalr	-1686(ra) # 8000424e <end_op>
      return -1;
    800058ec:	557d                	li	a0,-1
    800058ee:	b76d                	j	80005898 <sys_open+0xe4>
      end_op();
    800058f0:	fffff097          	auipc	ra,0xfffff
    800058f4:	95e080e7          	jalr	-1698(ra) # 8000424e <end_op>
      return -1;
    800058f8:	557d                	li	a0,-1
    800058fa:	bf79                	j	80005898 <sys_open+0xe4>
    iunlockput(ip);
    800058fc:	8526                	mv	a0,s1
    800058fe:	ffffe097          	auipc	ra,0xffffe
    80005902:	168080e7          	jalr	360(ra) # 80003a66 <iunlockput>
    end_op();
    80005906:	fffff097          	auipc	ra,0xfffff
    8000590a:	948080e7          	jalr	-1720(ra) # 8000424e <end_op>
    return -1;
    8000590e:	557d                	li	a0,-1
    80005910:	b761                	j	80005898 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005912:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005916:	04649783          	lh	a5,70(s1)
    8000591a:	02f99223          	sh	a5,36(s3)
    8000591e:	bf25                	j	80005856 <sys_open+0xa2>
    itrunc(ip);
    80005920:	8526                	mv	a0,s1
    80005922:	ffffe097          	auipc	ra,0xffffe
    80005926:	ff0080e7          	jalr	-16(ra) # 80003912 <itrunc>
    8000592a:	bfa9                	j	80005884 <sys_open+0xd0>
      fileclose(f);
    8000592c:	854e                	mv	a0,s3
    8000592e:	fffff097          	auipc	ra,0xfffff
    80005932:	d6a080e7          	jalr	-662(ra) # 80004698 <fileclose>
    iunlockput(ip);
    80005936:	8526                	mv	a0,s1
    80005938:	ffffe097          	auipc	ra,0xffffe
    8000593c:	12e080e7          	jalr	302(ra) # 80003a66 <iunlockput>
    end_op();
    80005940:	fffff097          	auipc	ra,0xfffff
    80005944:	90e080e7          	jalr	-1778(ra) # 8000424e <end_op>
    return -1;
    80005948:	557d                	li	a0,-1
    8000594a:	b7b9                	j	80005898 <sys_open+0xe4>

000000008000594c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000594c:	7175                	addi	sp,sp,-144
    8000594e:	e506                	sd	ra,136(sp)
    80005950:	e122                	sd	s0,128(sp)
    80005952:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005954:	fffff097          	auipc	ra,0xfffff
    80005958:	87c080e7          	jalr	-1924(ra) # 800041d0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000595c:	08000613          	li	a2,128
    80005960:	f7040593          	addi	a1,s0,-144
    80005964:	4501                	li	a0,0
    80005966:	ffffd097          	auipc	ra,0xffffd
    8000596a:	310080e7          	jalr	784(ra) # 80002c76 <argstr>
    8000596e:	02054963          	bltz	a0,800059a0 <sys_mkdir+0x54>
    80005972:	4681                	li	a3,0
    80005974:	4601                	li	a2,0
    80005976:	4585                	li	a1,1
    80005978:	f7040513          	addi	a0,s0,-144
    8000597c:	fffff097          	auipc	ra,0xfffff
    80005980:	7fc080e7          	jalr	2044(ra) # 80005178 <create>
    80005984:	cd11                	beqz	a0,800059a0 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005986:	ffffe097          	auipc	ra,0xffffe
    8000598a:	0e0080e7          	jalr	224(ra) # 80003a66 <iunlockput>
  end_op();
    8000598e:	fffff097          	auipc	ra,0xfffff
    80005992:	8c0080e7          	jalr	-1856(ra) # 8000424e <end_op>
  return 0;
    80005996:	4501                	li	a0,0
}
    80005998:	60aa                	ld	ra,136(sp)
    8000599a:	640a                	ld	s0,128(sp)
    8000599c:	6149                	addi	sp,sp,144
    8000599e:	8082                	ret
    end_op();
    800059a0:	fffff097          	auipc	ra,0xfffff
    800059a4:	8ae080e7          	jalr	-1874(ra) # 8000424e <end_op>
    return -1;
    800059a8:	557d                	li	a0,-1
    800059aa:	b7fd                	j	80005998 <sys_mkdir+0x4c>

00000000800059ac <sys_mknod>:

uint64
sys_mknod(void)
{
    800059ac:	7135                	addi	sp,sp,-160
    800059ae:	ed06                	sd	ra,152(sp)
    800059b0:	e922                	sd	s0,144(sp)
    800059b2:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800059b4:	fffff097          	auipc	ra,0xfffff
    800059b8:	81c080e7          	jalr	-2020(ra) # 800041d0 <begin_op>
  argint(1, &major);
    800059bc:	f6c40593          	addi	a1,s0,-148
    800059c0:	4505                	li	a0,1
    800059c2:	ffffd097          	auipc	ra,0xffffd
    800059c6:	274080e7          	jalr	628(ra) # 80002c36 <argint>
  argint(2, &minor);
    800059ca:	f6840593          	addi	a1,s0,-152
    800059ce:	4509                	li	a0,2
    800059d0:	ffffd097          	auipc	ra,0xffffd
    800059d4:	266080e7          	jalr	614(ra) # 80002c36 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059d8:	08000613          	li	a2,128
    800059dc:	f7040593          	addi	a1,s0,-144
    800059e0:	4501                	li	a0,0
    800059e2:	ffffd097          	auipc	ra,0xffffd
    800059e6:	294080e7          	jalr	660(ra) # 80002c76 <argstr>
    800059ea:	02054b63          	bltz	a0,80005a20 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800059ee:	f6841683          	lh	a3,-152(s0)
    800059f2:	f6c41603          	lh	a2,-148(s0)
    800059f6:	458d                	li	a1,3
    800059f8:	f7040513          	addi	a0,s0,-144
    800059fc:	fffff097          	auipc	ra,0xfffff
    80005a00:	77c080e7          	jalr	1916(ra) # 80005178 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a04:	cd11                	beqz	a0,80005a20 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a06:	ffffe097          	auipc	ra,0xffffe
    80005a0a:	060080e7          	jalr	96(ra) # 80003a66 <iunlockput>
  end_op();
    80005a0e:	fffff097          	auipc	ra,0xfffff
    80005a12:	840080e7          	jalr	-1984(ra) # 8000424e <end_op>
  return 0;
    80005a16:	4501                	li	a0,0
}
    80005a18:	60ea                	ld	ra,152(sp)
    80005a1a:	644a                	ld	s0,144(sp)
    80005a1c:	610d                	addi	sp,sp,160
    80005a1e:	8082                	ret
    end_op();
    80005a20:	fffff097          	auipc	ra,0xfffff
    80005a24:	82e080e7          	jalr	-2002(ra) # 8000424e <end_op>
    return -1;
    80005a28:	557d                	li	a0,-1
    80005a2a:	b7fd                	j	80005a18 <sys_mknod+0x6c>

0000000080005a2c <sys_chdir>:

uint64
sys_chdir(void)
{
    80005a2c:	7135                	addi	sp,sp,-160
    80005a2e:	ed06                	sd	ra,152(sp)
    80005a30:	e922                	sd	s0,144(sp)
    80005a32:	e526                	sd	s1,136(sp)
    80005a34:	e14a                	sd	s2,128(sp)
    80005a36:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a38:	ffffc097          	auipc	ra,0xffffc
    80005a3c:	f74080e7          	jalr	-140(ra) # 800019ac <myproc>
    80005a40:	892a                	mv	s2,a0
  
  begin_op();
    80005a42:	ffffe097          	auipc	ra,0xffffe
    80005a46:	78e080e7          	jalr	1934(ra) # 800041d0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a4a:	08000613          	li	a2,128
    80005a4e:	f6040593          	addi	a1,s0,-160
    80005a52:	4501                	li	a0,0
    80005a54:	ffffd097          	auipc	ra,0xffffd
    80005a58:	222080e7          	jalr	546(ra) # 80002c76 <argstr>
    80005a5c:	04054b63          	bltz	a0,80005ab2 <sys_chdir+0x86>
    80005a60:	f6040513          	addi	a0,s0,-160
    80005a64:	ffffe097          	auipc	ra,0xffffe
    80005a68:	54c080e7          	jalr	1356(ra) # 80003fb0 <namei>
    80005a6c:	84aa                	mv	s1,a0
    80005a6e:	c131                	beqz	a0,80005ab2 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a70:	ffffe097          	auipc	ra,0xffffe
    80005a74:	d94080e7          	jalr	-620(ra) # 80003804 <ilock>
  if(ip->type != T_DIR){
    80005a78:	04449703          	lh	a4,68(s1)
    80005a7c:	4785                	li	a5,1
    80005a7e:	04f71063          	bne	a4,a5,80005abe <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a82:	8526                	mv	a0,s1
    80005a84:	ffffe097          	auipc	ra,0xffffe
    80005a88:	e42080e7          	jalr	-446(ra) # 800038c6 <iunlock>
  iput(p->cwd);
    80005a8c:	15093503          	ld	a0,336(s2)
    80005a90:	ffffe097          	auipc	ra,0xffffe
    80005a94:	f2e080e7          	jalr	-210(ra) # 800039be <iput>
  end_op();
    80005a98:	ffffe097          	auipc	ra,0xffffe
    80005a9c:	7b6080e7          	jalr	1974(ra) # 8000424e <end_op>
  p->cwd = ip;
    80005aa0:	14993823          	sd	s1,336(s2)
  return 0;
    80005aa4:	4501                	li	a0,0
}
    80005aa6:	60ea                	ld	ra,152(sp)
    80005aa8:	644a                	ld	s0,144(sp)
    80005aaa:	64aa                	ld	s1,136(sp)
    80005aac:	690a                	ld	s2,128(sp)
    80005aae:	610d                	addi	sp,sp,160
    80005ab0:	8082                	ret
    end_op();
    80005ab2:	ffffe097          	auipc	ra,0xffffe
    80005ab6:	79c080e7          	jalr	1948(ra) # 8000424e <end_op>
    return -1;
    80005aba:	557d                	li	a0,-1
    80005abc:	b7ed                	j	80005aa6 <sys_chdir+0x7a>
    iunlockput(ip);
    80005abe:	8526                	mv	a0,s1
    80005ac0:	ffffe097          	auipc	ra,0xffffe
    80005ac4:	fa6080e7          	jalr	-90(ra) # 80003a66 <iunlockput>
    end_op();
    80005ac8:	ffffe097          	auipc	ra,0xffffe
    80005acc:	786080e7          	jalr	1926(ra) # 8000424e <end_op>
    return -1;
    80005ad0:	557d                	li	a0,-1
    80005ad2:	bfd1                	j	80005aa6 <sys_chdir+0x7a>

0000000080005ad4 <sys_exec>:

uint64
sys_exec(void)
{
    80005ad4:	7145                	addi	sp,sp,-464
    80005ad6:	e786                	sd	ra,456(sp)
    80005ad8:	e3a2                	sd	s0,448(sp)
    80005ada:	ff26                	sd	s1,440(sp)
    80005adc:	fb4a                	sd	s2,432(sp)
    80005ade:	f74e                	sd	s3,424(sp)
    80005ae0:	f352                	sd	s4,416(sp)
    80005ae2:	ef56                	sd	s5,408(sp)
    80005ae4:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005ae6:	e3840593          	addi	a1,s0,-456
    80005aea:	4505                	li	a0,1
    80005aec:	ffffd097          	auipc	ra,0xffffd
    80005af0:	16a080e7          	jalr	362(ra) # 80002c56 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005af4:	08000613          	li	a2,128
    80005af8:	f4040593          	addi	a1,s0,-192
    80005afc:	4501                	li	a0,0
    80005afe:	ffffd097          	auipc	ra,0xffffd
    80005b02:	178080e7          	jalr	376(ra) # 80002c76 <argstr>
    80005b06:	87aa                	mv	a5,a0
    return -1;
    80005b08:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005b0a:	0c07c363          	bltz	a5,80005bd0 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005b0e:	10000613          	li	a2,256
    80005b12:	4581                	li	a1,0
    80005b14:	e4040513          	addi	a0,s0,-448
    80005b18:	ffffb097          	auipc	ra,0xffffb
    80005b1c:	1ba080e7          	jalr	442(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005b20:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005b24:	89a6                	mv	s3,s1
    80005b26:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005b28:	02000a13          	li	s4,32
    80005b2c:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005b30:	00391513          	slli	a0,s2,0x3
    80005b34:	e3040593          	addi	a1,s0,-464
    80005b38:	e3843783          	ld	a5,-456(s0)
    80005b3c:	953e                	add	a0,a0,a5
    80005b3e:	ffffd097          	auipc	ra,0xffffd
    80005b42:	05a080e7          	jalr	90(ra) # 80002b98 <fetchaddr>
    80005b46:	02054a63          	bltz	a0,80005b7a <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005b4a:	e3043783          	ld	a5,-464(s0)
    80005b4e:	c3b9                	beqz	a5,80005b94 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b50:	ffffb097          	auipc	ra,0xffffb
    80005b54:	f96080e7          	jalr	-106(ra) # 80000ae6 <kalloc>
    80005b58:	85aa                	mv	a1,a0
    80005b5a:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b5e:	cd11                	beqz	a0,80005b7a <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b60:	6605                	lui	a2,0x1
    80005b62:	e3043503          	ld	a0,-464(s0)
    80005b66:	ffffd097          	auipc	ra,0xffffd
    80005b6a:	084080e7          	jalr	132(ra) # 80002bea <fetchstr>
    80005b6e:	00054663          	bltz	a0,80005b7a <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005b72:	0905                	addi	s2,s2,1
    80005b74:	09a1                	addi	s3,s3,8
    80005b76:	fb491be3          	bne	s2,s4,80005b2c <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b7a:	f4040913          	addi	s2,s0,-192
    80005b7e:	6088                	ld	a0,0(s1)
    80005b80:	c539                	beqz	a0,80005bce <sys_exec+0xfa>
    kfree(argv[i]);
    80005b82:	ffffb097          	auipc	ra,0xffffb
    80005b86:	e66080e7          	jalr	-410(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b8a:	04a1                	addi	s1,s1,8
    80005b8c:	ff2499e3          	bne	s1,s2,80005b7e <sys_exec+0xaa>
  return -1;
    80005b90:	557d                	li	a0,-1
    80005b92:	a83d                	j	80005bd0 <sys_exec+0xfc>
      argv[i] = 0;
    80005b94:	0a8e                	slli	s5,s5,0x3
    80005b96:	fc0a8793          	addi	a5,s5,-64
    80005b9a:	00878ab3          	add	s5,a5,s0
    80005b9e:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005ba2:	e4040593          	addi	a1,s0,-448
    80005ba6:	f4040513          	addi	a0,s0,-192
    80005baa:	fffff097          	auipc	ra,0xfffff
    80005bae:	168080e7          	jalr	360(ra) # 80004d12 <exec>
    80005bb2:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bb4:	f4040993          	addi	s3,s0,-192
    80005bb8:	6088                	ld	a0,0(s1)
    80005bba:	c901                	beqz	a0,80005bca <sys_exec+0xf6>
    kfree(argv[i]);
    80005bbc:	ffffb097          	auipc	ra,0xffffb
    80005bc0:	e2c080e7          	jalr	-468(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bc4:	04a1                	addi	s1,s1,8
    80005bc6:	ff3499e3          	bne	s1,s3,80005bb8 <sys_exec+0xe4>
  return ret;
    80005bca:	854a                	mv	a0,s2
    80005bcc:	a011                	j	80005bd0 <sys_exec+0xfc>
  return -1;
    80005bce:	557d                	li	a0,-1
}
    80005bd0:	60be                	ld	ra,456(sp)
    80005bd2:	641e                	ld	s0,448(sp)
    80005bd4:	74fa                	ld	s1,440(sp)
    80005bd6:	795a                	ld	s2,432(sp)
    80005bd8:	79ba                	ld	s3,424(sp)
    80005bda:	7a1a                	ld	s4,416(sp)
    80005bdc:	6afa                	ld	s5,408(sp)
    80005bde:	6179                	addi	sp,sp,464
    80005be0:	8082                	ret

0000000080005be2 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005be2:	7139                	addi	sp,sp,-64
    80005be4:	fc06                	sd	ra,56(sp)
    80005be6:	f822                	sd	s0,48(sp)
    80005be8:	f426                	sd	s1,40(sp)
    80005bea:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005bec:	ffffc097          	auipc	ra,0xffffc
    80005bf0:	dc0080e7          	jalr	-576(ra) # 800019ac <myproc>
    80005bf4:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005bf6:	fd840593          	addi	a1,s0,-40
    80005bfa:	4501                	li	a0,0
    80005bfc:	ffffd097          	auipc	ra,0xffffd
    80005c00:	05a080e7          	jalr	90(ra) # 80002c56 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005c04:	fc840593          	addi	a1,s0,-56
    80005c08:	fd040513          	addi	a0,s0,-48
    80005c0c:	fffff097          	auipc	ra,0xfffff
    80005c10:	dbc080e7          	jalr	-580(ra) # 800049c8 <pipealloc>
    return -1;
    80005c14:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005c16:	0c054463          	bltz	a0,80005cde <sys_pipe+0xfc>
  fd0 = -1;
    80005c1a:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005c1e:	fd043503          	ld	a0,-48(s0)
    80005c22:	fffff097          	auipc	ra,0xfffff
    80005c26:	514080e7          	jalr	1300(ra) # 80005136 <fdalloc>
    80005c2a:	fca42223          	sw	a0,-60(s0)
    80005c2e:	08054b63          	bltz	a0,80005cc4 <sys_pipe+0xe2>
    80005c32:	fc843503          	ld	a0,-56(s0)
    80005c36:	fffff097          	auipc	ra,0xfffff
    80005c3a:	500080e7          	jalr	1280(ra) # 80005136 <fdalloc>
    80005c3e:	fca42023          	sw	a0,-64(s0)
    80005c42:	06054863          	bltz	a0,80005cb2 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c46:	4691                	li	a3,4
    80005c48:	fc440613          	addi	a2,s0,-60
    80005c4c:	fd843583          	ld	a1,-40(s0)
    80005c50:	68a8                	ld	a0,80(s1)
    80005c52:	ffffc097          	auipc	ra,0xffffc
    80005c56:	a1a080e7          	jalr	-1510(ra) # 8000166c <copyout>
    80005c5a:	02054063          	bltz	a0,80005c7a <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c5e:	4691                	li	a3,4
    80005c60:	fc040613          	addi	a2,s0,-64
    80005c64:	fd843583          	ld	a1,-40(s0)
    80005c68:	0591                	addi	a1,a1,4
    80005c6a:	68a8                	ld	a0,80(s1)
    80005c6c:	ffffc097          	auipc	ra,0xffffc
    80005c70:	a00080e7          	jalr	-1536(ra) # 8000166c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c74:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c76:	06055463          	bgez	a0,80005cde <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005c7a:	fc442783          	lw	a5,-60(s0)
    80005c7e:	07e9                	addi	a5,a5,26
    80005c80:	078e                	slli	a5,a5,0x3
    80005c82:	97a6                	add	a5,a5,s1
    80005c84:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c88:	fc042783          	lw	a5,-64(s0)
    80005c8c:	07e9                	addi	a5,a5,26
    80005c8e:	078e                	slli	a5,a5,0x3
    80005c90:	94be                	add	s1,s1,a5
    80005c92:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005c96:	fd043503          	ld	a0,-48(s0)
    80005c9a:	fffff097          	auipc	ra,0xfffff
    80005c9e:	9fe080e7          	jalr	-1538(ra) # 80004698 <fileclose>
    fileclose(wf);
    80005ca2:	fc843503          	ld	a0,-56(s0)
    80005ca6:	fffff097          	auipc	ra,0xfffff
    80005caa:	9f2080e7          	jalr	-1550(ra) # 80004698 <fileclose>
    return -1;
    80005cae:	57fd                	li	a5,-1
    80005cb0:	a03d                	j	80005cde <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005cb2:	fc442783          	lw	a5,-60(s0)
    80005cb6:	0007c763          	bltz	a5,80005cc4 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005cba:	07e9                	addi	a5,a5,26
    80005cbc:	078e                	slli	a5,a5,0x3
    80005cbe:	97a6                	add	a5,a5,s1
    80005cc0:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005cc4:	fd043503          	ld	a0,-48(s0)
    80005cc8:	fffff097          	auipc	ra,0xfffff
    80005ccc:	9d0080e7          	jalr	-1584(ra) # 80004698 <fileclose>
    fileclose(wf);
    80005cd0:	fc843503          	ld	a0,-56(s0)
    80005cd4:	fffff097          	auipc	ra,0xfffff
    80005cd8:	9c4080e7          	jalr	-1596(ra) # 80004698 <fileclose>
    return -1;
    80005cdc:	57fd                	li	a5,-1
}
    80005cde:	853e                	mv	a0,a5
    80005ce0:	70e2                	ld	ra,56(sp)
    80005ce2:	7442                	ld	s0,48(sp)
    80005ce4:	74a2                	ld	s1,40(sp)
    80005ce6:	6121                	addi	sp,sp,64
    80005ce8:	8082                	ret
    80005cea:	0000                	unimp
    80005cec:	0000                	unimp
	...

0000000080005cf0 <kernelvec>:
    80005cf0:	7111                	addi	sp,sp,-256
    80005cf2:	e006                	sd	ra,0(sp)
    80005cf4:	e40a                	sd	sp,8(sp)
    80005cf6:	e80e                	sd	gp,16(sp)
    80005cf8:	ec12                	sd	tp,24(sp)
    80005cfa:	f016                	sd	t0,32(sp)
    80005cfc:	f41a                	sd	t1,40(sp)
    80005cfe:	f81e                	sd	t2,48(sp)
    80005d00:	fc22                	sd	s0,56(sp)
    80005d02:	e0a6                	sd	s1,64(sp)
    80005d04:	e4aa                	sd	a0,72(sp)
    80005d06:	e8ae                	sd	a1,80(sp)
    80005d08:	ecb2                	sd	a2,88(sp)
    80005d0a:	f0b6                	sd	a3,96(sp)
    80005d0c:	f4ba                	sd	a4,104(sp)
    80005d0e:	f8be                	sd	a5,112(sp)
    80005d10:	fcc2                	sd	a6,120(sp)
    80005d12:	e146                	sd	a7,128(sp)
    80005d14:	e54a                	sd	s2,136(sp)
    80005d16:	e94e                	sd	s3,144(sp)
    80005d18:	ed52                	sd	s4,152(sp)
    80005d1a:	f156                	sd	s5,160(sp)
    80005d1c:	f55a                	sd	s6,168(sp)
    80005d1e:	f95e                	sd	s7,176(sp)
    80005d20:	fd62                	sd	s8,184(sp)
    80005d22:	e1e6                	sd	s9,192(sp)
    80005d24:	e5ea                	sd	s10,200(sp)
    80005d26:	e9ee                	sd	s11,208(sp)
    80005d28:	edf2                	sd	t3,216(sp)
    80005d2a:	f1f6                	sd	t4,224(sp)
    80005d2c:	f5fa                	sd	t5,232(sp)
    80005d2e:	f9fe                	sd	t6,240(sp)
    80005d30:	d35fc0ef          	jal	ra,80002a64 <kerneltrap>
    80005d34:	6082                	ld	ra,0(sp)
    80005d36:	6122                	ld	sp,8(sp)
    80005d38:	61c2                	ld	gp,16(sp)
    80005d3a:	7282                	ld	t0,32(sp)
    80005d3c:	7322                	ld	t1,40(sp)
    80005d3e:	73c2                	ld	t2,48(sp)
    80005d40:	7462                	ld	s0,56(sp)
    80005d42:	6486                	ld	s1,64(sp)
    80005d44:	6526                	ld	a0,72(sp)
    80005d46:	65c6                	ld	a1,80(sp)
    80005d48:	6666                	ld	a2,88(sp)
    80005d4a:	7686                	ld	a3,96(sp)
    80005d4c:	7726                	ld	a4,104(sp)
    80005d4e:	77c6                	ld	a5,112(sp)
    80005d50:	7866                	ld	a6,120(sp)
    80005d52:	688a                	ld	a7,128(sp)
    80005d54:	692a                	ld	s2,136(sp)
    80005d56:	69ca                	ld	s3,144(sp)
    80005d58:	6a6a                	ld	s4,152(sp)
    80005d5a:	7a8a                	ld	s5,160(sp)
    80005d5c:	7b2a                	ld	s6,168(sp)
    80005d5e:	7bca                	ld	s7,176(sp)
    80005d60:	7c6a                	ld	s8,184(sp)
    80005d62:	6c8e                	ld	s9,192(sp)
    80005d64:	6d2e                	ld	s10,200(sp)
    80005d66:	6dce                	ld	s11,208(sp)
    80005d68:	6e6e                	ld	t3,216(sp)
    80005d6a:	7e8e                	ld	t4,224(sp)
    80005d6c:	7f2e                	ld	t5,232(sp)
    80005d6e:	7fce                	ld	t6,240(sp)
    80005d70:	6111                	addi	sp,sp,256
    80005d72:	10200073          	sret
    80005d76:	00000013          	nop
    80005d7a:	00000013          	nop
    80005d7e:	0001                	nop

0000000080005d80 <timervec>:
    80005d80:	34051573          	csrrw	a0,mscratch,a0
    80005d84:	e10c                	sd	a1,0(a0)
    80005d86:	e510                	sd	a2,8(a0)
    80005d88:	e914                	sd	a3,16(a0)
    80005d8a:	6d0c                	ld	a1,24(a0)
    80005d8c:	7110                	ld	a2,32(a0)
    80005d8e:	6194                	ld	a3,0(a1)
    80005d90:	96b2                	add	a3,a3,a2
    80005d92:	e194                	sd	a3,0(a1)
    80005d94:	4589                	li	a1,2
    80005d96:	14459073          	csrw	sip,a1
    80005d9a:	6914                	ld	a3,16(a0)
    80005d9c:	6510                	ld	a2,8(a0)
    80005d9e:	610c                	ld	a1,0(a0)
    80005da0:	34051573          	csrrw	a0,mscratch,a0
    80005da4:	30200073          	mret
	...

0000000080005daa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005daa:	1141                	addi	sp,sp,-16
    80005dac:	e422                	sd	s0,8(sp)
    80005dae:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005db0:	0c0007b7          	lui	a5,0xc000
    80005db4:	4705                	li	a4,1
    80005db6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005db8:	c3d8                	sw	a4,4(a5)
}
    80005dba:	6422                	ld	s0,8(sp)
    80005dbc:	0141                	addi	sp,sp,16
    80005dbe:	8082                	ret

0000000080005dc0 <plicinithart>:

void
plicinithart(void)
{
    80005dc0:	1141                	addi	sp,sp,-16
    80005dc2:	e406                	sd	ra,8(sp)
    80005dc4:	e022                	sd	s0,0(sp)
    80005dc6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005dc8:	ffffc097          	auipc	ra,0xffffc
    80005dcc:	bb8080e7          	jalr	-1096(ra) # 80001980 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005dd0:	0085171b          	slliw	a4,a0,0x8
    80005dd4:	0c0027b7          	lui	a5,0xc002
    80005dd8:	97ba                	add	a5,a5,a4
    80005dda:	40200713          	li	a4,1026
    80005dde:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005de2:	00d5151b          	slliw	a0,a0,0xd
    80005de6:	0c2017b7          	lui	a5,0xc201
    80005dea:	97aa                	add	a5,a5,a0
    80005dec:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005df0:	60a2                	ld	ra,8(sp)
    80005df2:	6402                	ld	s0,0(sp)
    80005df4:	0141                	addi	sp,sp,16
    80005df6:	8082                	ret

0000000080005df8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005df8:	1141                	addi	sp,sp,-16
    80005dfa:	e406                	sd	ra,8(sp)
    80005dfc:	e022                	sd	s0,0(sp)
    80005dfe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e00:	ffffc097          	auipc	ra,0xffffc
    80005e04:	b80080e7          	jalr	-1152(ra) # 80001980 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005e08:	00d5151b          	slliw	a0,a0,0xd
    80005e0c:	0c2017b7          	lui	a5,0xc201
    80005e10:	97aa                	add	a5,a5,a0
  return irq;
}
    80005e12:	43c8                	lw	a0,4(a5)
    80005e14:	60a2                	ld	ra,8(sp)
    80005e16:	6402                	ld	s0,0(sp)
    80005e18:	0141                	addi	sp,sp,16
    80005e1a:	8082                	ret

0000000080005e1c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005e1c:	1101                	addi	sp,sp,-32
    80005e1e:	ec06                	sd	ra,24(sp)
    80005e20:	e822                	sd	s0,16(sp)
    80005e22:	e426                	sd	s1,8(sp)
    80005e24:	1000                	addi	s0,sp,32
    80005e26:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005e28:	ffffc097          	auipc	ra,0xffffc
    80005e2c:	b58080e7          	jalr	-1192(ra) # 80001980 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005e30:	00d5151b          	slliw	a0,a0,0xd
    80005e34:	0c2017b7          	lui	a5,0xc201
    80005e38:	97aa                	add	a5,a5,a0
    80005e3a:	c3c4                	sw	s1,4(a5)
}
    80005e3c:	60e2                	ld	ra,24(sp)
    80005e3e:	6442                	ld	s0,16(sp)
    80005e40:	64a2                	ld	s1,8(sp)
    80005e42:	6105                	addi	sp,sp,32
    80005e44:	8082                	ret

0000000080005e46 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005e46:	1141                	addi	sp,sp,-16
    80005e48:	e406                	sd	ra,8(sp)
    80005e4a:	e022                	sd	s0,0(sp)
    80005e4c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005e4e:	479d                	li	a5,7
    80005e50:	04a7cc63          	blt	a5,a0,80005ea8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005e54:	0001c797          	auipc	a5,0x1c
    80005e58:	07c78793          	addi	a5,a5,124 # 80021ed0 <disk>
    80005e5c:	97aa                	add	a5,a5,a0
    80005e5e:	0187c783          	lbu	a5,24(a5)
    80005e62:	ebb9                	bnez	a5,80005eb8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005e64:	00451693          	slli	a3,a0,0x4
    80005e68:	0001c797          	auipc	a5,0x1c
    80005e6c:	06878793          	addi	a5,a5,104 # 80021ed0 <disk>
    80005e70:	6398                	ld	a4,0(a5)
    80005e72:	9736                	add	a4,a4,a3
    80005e74:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80005e78:	6398                	ld	a4,0(a5)
    80005e7a:	9736                	add	a4,a4,a3
    80005e7c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005e80:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005e84:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005e88:	97aa                	add	a5,a5,a0
    80005e8a:	4705                	li	a4,1
    80005e8c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80005e90:	0001c517          	auipc	a0,0x1c
    80005e94:	05850513          	addi	a0,a0,88 # 80021ee8 <disk+0x18>
    80005e98:	ffffc097          	auipc	ra,0xffffc
    80005e9c:	232080e7          	jalr	562(ra) # 800020ca <wakeup>
}
    80005ea0:	60a2                	ld	ra,8(sp)
    80005ea2:	6402                	ld	s0,0(sp)
    80005ea4:	0141                	addi	sp,sp,16
    80005ea6:	8082                	ret
    panic("free_desc 1");
    80005ea8:	00003517          	auipc	a0,0x3
    80005eac:	94050513          	addi	a0,a0,-1728 # 800087e8 <syscalls+0x300>
    80005eb0:	ffffa097          	auipc	ra,0xffffa
    80005eb4:	690080e7          	jalr	1680(ra) # 80000540 <panic>
    panic("free_desc 2");
    80005eb8:	00003517          	auipc	a0,0x3
    80005ebc:	94050513          	addi	a0,a0,-1728 # 800087f8 <syscalls+0x310>
    80005ec0:	ffffa097          	auipc	ra,0xffffa
    80005ec4:	680080e7          	jalr	1664(ra) # 80000540 <panic>

0000000080005ec8 <virtio_disk_init>:
{
    80005ec8:	1101                	addi	sp,sp,-32
    80005eca:	ec06                	sd	ra,24(sp)
    80005ecc:	e822                	sd	s0,16(sp)
    80005ece:	e426                	sd	s1,8(sp)
    80005ed0:	e04a                	sd	s2,0(sp)
    80005ed2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005ed4:	00003597          	auipc	a1,0x3
    80005ed8:	93458593          	addi	a1,a1,-1740 # 80008808 <syscalls+0x320>
    80005edc:	0001c517          	auipc	a0,0x1c
    80005ee0:	11c50513          	addi	a0,a0,284 # 80021ff8 <disk+0x128>
    80005ee4:	ffffb097          	auipc	ra,0xffffb
    80005ee8:	c62080e7          	jalr	-926(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005eec:	100017b7          	lui	a5,0x10001
    80005ef0:	4398                	lw	a4,0(a5)
    80005ef2:	2701                	sext.w	a4,a4
    80005ef4:	747277b7          	lui	a5,0x74727
    80005ef8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005efc:	14f71b63          	bne	a4,a5,80006052 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005f00:	100017b7          	lui	a5,0x10001
    80005f04:	43dc                	lw	a5,4(a5)
    80005f06:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f08:	4709                	li	a4,2
    80005f0a:	14e79463          	bne	a5,a4,80006052 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f0e:	100017b7          	lui	a5,0x10001
    80005f12:	479c                	lw	a5,8(a5)
    80005f14:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005f16:	12e79e63          	bne	a5,a4,80006052 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005f1a:	100017b7          	lui	a5,0x10001
    80005f1e:	47d8                	lw	a4,12(a5)
    80005f20:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f22:	554d47b7          	lui	a5,0x554d4
    80005f26:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005f2a:	12f71463          	bne	a4,a5,80006052 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f2e:	100017b7          	lui	a5,0x10001
    80005f32:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f36:	4705                	li	a4,1
    80005f38:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f3a:	470d                	li	a4,3
    80005f3c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005f3e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005f40:	c7ffe6b7          	lui	a3,0xc7ffe
    80005f44:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc74f>
    80005f48:	8f75                	and	a4,a4,a3
    80005f4a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f4c:	472d                	li	a4,11
    80005f4e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005f50:	5bbc                	lw	a5,112(a5)
    80005f52:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005f56:	8ba1                	andi	a5,a5,8
    80005f58:	10078563          	beqz	a5,80006062 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f5c:	100017b7          	lui	a5,0x10001
    80005f60:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005f64:	43fc                	lw	a5,68(a5)
    80005f66:	2781                	sext.w	a5,a5
    80005f68:	10079563          	bnez	a5,80006072 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f6c:	100017b7          	lui	a5,0x10001
    80005f70:	5bdc                	lw	a5,52(a5)
    80005f72:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f74:	10078763          	beqz	a5,80006082 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80005f78:	471d                	li	a4,7
    80005f7a:	10f77c63          	bgeu	a4,a5,80006092 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    80005f7e:	ffffb097          	auipc	ra,0xffffb
    80005f82:	b68080e7          	jalr	-1176(ra) # 80000ae6 <kalloc>
    80005f86:	0001c497          	auipc	s1,0x1c
    80005f8a:	f4a48493          	addi	s1,s1,-182 # 80021ed0 <disk>
    80005f8e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005f90:	ffffb097          	auipc	ra,0xffffb
    80005f94:	b56080e7          	jalr	-1194(ra) # 80000ae6 <kalloc>
    80005f98:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005f9a:	ffffb097          	auipc	ra,0xffffb
    80005f9e:	b4c080e7          	jalr	-1204(ra) # 80000ae6 <kalloc>
    80005fa2:	87aa                	mv	a5,a0
    80005fa4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005fa6:	6088                	ld	a0,0(s1)
    80005fa8:	cd6d                	beqz	a0,800060a2 <virtio_disk_init+0x1da>
    80005faa:	0001c717          	auipc	a4,0x1c
    80005fae:	f2e73703          	ld	a4,-210(a4) # 80021ed8 <disk+0x8>
    80005fb2:	cb65                	beqz	a4,800060a2 <virtio_disk_init+0x1da>
    80005fb4:	c7fd                	beqz	a5,800060a2 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80005fb6:	6605                	lui	a2,0x1
    80005fb8:	4581                	li	a1,0
    80005fba:	ffffb097          	auipc	ra,0xffffb
    80005fbe:	d18080e7          	jalr	-744(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005fc2:	0001c497          	auipc	s1,0x1c
    80005fc6:	f0e48493          	addi	s1,s1,-242 # 80021ed0 <disk>
    80005fca:	6605                	lui	a2,0x1
    80005fcc:	4581                	li	a1,0
    80005fce:	6488                	ld	a0,8(s1)
    80005fd0:	ffffb097          	auipc	ra,0xffffb
    80005fd4:	d02080e7          	jalr	-766(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    80005fd8:	6605                	lui	a2,0x1
    80005fda:	4581                	li	a1,0
    80005fdc:	6888                	ld	a0,16(s1)
    80005fde:	ffffb097          	auipc	ra,0xffffb
    80005fe2:	cf4080e7          	jalr	-780(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005fe6:	100017b7          	lui	a5,0x10001
    80005fea:	4721                	li	a4,8
    80005fec:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005fee:	4098                	lw	a4,0(s1)
    80005ff0:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005ff4:	40d8                	lw	a4,4(s1)
    80005ff6:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005ffa:	6498                	ld	a4,8(s1)
    80005ffc:	0007069b          	sext.w	a3,a4
    80006000:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006004:	9701                	srai	a4,a4,0x20
    80006006:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000600a:	6898                	ld	a4,16(s1)
    8000600c:	0007069b          	sext.w	a3,a4
    80006010:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006014:	9701                	srai	a4,a4,0x20
    80006016:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000601a:	4705                	li	a4,1
    8000601c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000601e:	00e48c23          	sb	a4,24(s1)
    80006022:	00e48ca3          	sb	a4,25(s1)
    80006026:	00e48d23          	sb	a4,26(s1)
    8000602a:	00e48da3          	sb	a4,27(s1)
    8000602e:	00e48e23          	sb	a4,28(s1)
    80006032:	00e48ea3          	sb	a4,29(s1)
    80006036:	00e48f23          	sb	a4,30(s1)
    8000603a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000603e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006042:	0727a823          	sw	s2,112(a5)
}
    80006046:	60e2                	ld	ra,24(sp)
    80006048:	6442                	ld	s0,16(sp)
    8000604a:	64a2                	ld	s1,8(sp)
    8000604c:	6902                	ld	s2,0(sp)
    8000604e:	6105                	addi	sp,sp,32
    80006050:	8082                	ret
    panic("could not find virtio disk");
    80006052:	00002517          	auipc	a0,0x2
    80006056:	7c650513          	addi	a0,a0,1990 # 80008818 <syscalls+0x330>
    8000605a:	ffffa097          	auipc	ra,0xffffa
    8000605e:	4e6080e7          	jalr	1254(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006062:	00002517          	auipc	a0,0x2
    80006066:	7d650513          	addi	a0,a0,2006 # 80008838 <syscalls+0x350>
    8000606a:	ffffa097          	auipc	ra,0xffffa
    8000606e:	4d6080e7          	jalr	1238(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80006072:	00002517          	auipc	a0,0x2
    80006076:	7e650513          	addi	a0,a0,2022 # 80008858 <syscalls+0x370>
    8000607a:	ffffa097          	auipc	ra,0xffffa
    8000607e:	4c6080e7          	jalr	1222(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006082:	00002517          	auipc	a0,0x2
    80006086:	7f650513          	addi	a0,a0,2038 # 80008878 <syscalls+0x390>
    8000608a:	ffffa097          	auipc	ra,0xffffa
    8000608e:	4b6080e7          	jalr	1206(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006092:	00003517          	auipc	a0,0x3
    80006096:	80650513          	addi	a0,a0,-2042 # 80008898 <syscalls+0x3b0>
    8000609a:	ffffa097          	auipc	ra,0xffffa
    8000609e:	4a6080e7          	jalr	1190(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    800060a2:	00003517          	auipc	a0,0x3
    800060a6:	81650513          	addi	a0,a0,-2026 # 800088b8 <syscalls+0x3d0>
    800060aa:	ffffa097          	auipc	ra,0xffffa
    800060ae:	496080e7          	jalr	1174(ra) # 80000540 <panic>

00000000800060b2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800060b2:	7119                	addi	sp,sp,-128
    800060b4:	fc86                	sd	ra,120(sp)
    800060b6:	f8a2                	sd	s0,112(sp)
    800060b8:	f4a6                	sd	s1,104(sp)
    800060ba:	f0ca                	sd	s2,96(sp)
    800060bc:	ecce                	sd	s3,88(sp)
    800060be:	e8d2                	sd	s4,80(sp)
    800060c0:	e4d6                	sd	s5,72(sp)
    800060c2:	e0da                	sd	s6,64(sp)
    800060c4:	fc5e                	sd	s7,56(sp)
    800060c6:	f862                	sd	s8,48(sp)
    800060c8:	f466                	sd	s9,40(sp)
    800060ca:	f06a                	sd	s10,32(sp)
    800060cc:	ec6e                	sd	s11,24(sp)
    800060ce:	0100                	addi	s0,sp,128
    800060d0:	8aaa                	mv	s5,a0
    800060d2:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800060d4:	00c52d03          	lw	s10,12(a0)
    800060d8:	001d1d1b          	slliw	s10,s10,0x1
    800060dc:	1d02                	slli	s10,s10,0x20
    800060de:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800060e2:	0001c517          	auipc	a0,0x1c
    800060e6:	f1650513          	addi	a0,a0,-234 # 80021ff8 <disk+0x128>
    800060ea:	ffffb097          	auipc	ra,0xffffb
    800060ee:	aec080e7          	jalr	-1300(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    800060f2:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800060f4:	44a1                	li	s1,8
      disk.free[i] = 0;
    800060f6:	0001cb97          	auipc	s7,0x1c
    800060fa:	ddab8b93          	addi	s7,s7,-550 # 80021ed0 <disk>
  for(int i = 0; i < 3; i++){
    800060fe:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006100:	0001cc97          	auipc	s9,0x1c
    80006104:	ef8c8c93          	addi	s9,s9,-264 # 80021ff8 <disk+0x128>
    80006108:	a08d                	j	8000616a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000610a:	00fb8733          	add	a4,s7,a5
    8000610e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006112:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006114:	0207c563          	bltz	a5,8000613e <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80006118:	2905                	addiw	s2,s2,1
    8000611a:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    8000611c:	05690c63          	beq	s2,s6,80006174 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006120:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006122:	0001c717          	auipc	a4,0x1c
    80006126:	dae70713          	addi	a4,a4,-594 # 80021ed0 <disk>
    8000612a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000612c:	01874683          	lbu	a3,24(a4)
    80006130:	fee9                	bnez	a3,8000610a <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006132:	2785                	addiw	a5,a5,1
    80006134:	0705                	addi	a4,a4,1
    80006136:	fe979be3          	bne	a5,s1,8000612c <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000613a:	57fd                	li	a5,-1
    8000613c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000613e:	01205d63          	blez	s2,80006158 <virtio_disk_rw+0xa6>
    80006142:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006144:	000a2503          	lw	a0,0(s4)
    80006148:	00000097          	auipc	ra,0x0
    8000614c:	cfe080e7          	jalr	-770(ra) # 80005e46 <free_desc>
      for(int j = 0; j < i; j++)
    80006150:	2d85                	addiw	s11,s11,1
    80006152:	0a11                	addi	s4,s4,4
    80006154:	ff2d98e3          	bne	s11,s2,80006144 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006158:	85e6                	mv	a1,s9
    8000615a:	0001c517          	auipc	a0,0x1c
    8000615e:	d8e50513          	addi	a0,a0,-626 # 80021ee8 <disk+0x18>
    80006162:	ffffc097          	auipc	ra,0xffffc
    80006166:	f04080e7          	jalr	-252(ra) # 80002066 <sleep>
  for(int i = 0; i < 3; i++){
    8000616a:	f8040a13          	addi	s4,s0,-128
{
    8000616e:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006170:	894e                	mv	s2,s3
    80006172:	b77d                	j	80006120 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006174:	f8042503          	lw	a0,-128(s0)
    80006178:	00a50713          	addi	a4,a0,10
    8000617c:	0712                	slli	a4,a4,0x4

  if(write)
    8000617e:	0001c797          	auipc	a5,0x1c
    80006182:	d5278793          	addi	a5,a5,-686 # 80021ed0 <disk>
    80006186:	00e786b3          	add	a3,a5,a4
    8000618a:	01803633          	snez	a2,s8
    8000618e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006190:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006194:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006198:	f6070613          	addi	a2,a4,-160
    8000619c:	6394                	ld	a3,0(a5)
    8000619e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800061a0:	00870593          	addi	a1,a4,8
    800061a4:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    800061a6:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800061a8:	0007b803          	ld	a6,0(a5)
    800061ac:	9642                	add	a2,a2,a6
    800061ae:	46c1                	li	a3,16
    800061b0:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800061b2:	4585                	li	a1,1
    800061b4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    800061b8:	f8442683          	lw	a3,-124(s0)
    800061bc:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800061c0:	0692                	slli	a3,a3,0x4
    800061c2:	9836                	add	a6,a6,a3
    800061c4:	058a8613          	addi	a2,s5,88
    800061c8:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    800061cc:	0007b803          	ld	a6,0(a5)
    800061d0:	96c2                	add	a3,a3,a6
    800061d2:	40000613          	li	a2,1024
    800061d6:	c690                	sw	a2,8(a3)
  if(write)
    800061d8:	001c3613          	seqz	a2,s8
    800061dc:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800061e0:	00166613          	ori	a2,a2,1
    800061e4:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800061e8:	f8842603          	lw	a2,-120(s0)
    800061ec:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800061f0:	00250693          	addi	a3,a0,2
    800061f4:	0692                	slli	a3,a3,0x4
    800061f6:	96be                	add	a3,a3,a5
    800061f8:	58fd                	li	a7,-1
    800061fa:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800061fe:	0612                	slli	a2,a2,0x4
    80006200:	9832                	add	a6,a6,a2
    80006202:	f9070713          	addi	a4,a4,-112
    80006206:	973e                	add	a4,a4,a5
    80006208:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000620c:	6398                	ld	a4,0(a5)
    8000620e:	9732                	add	a4,a4,a2
    80006210:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006212:	4609                	li	a2,2
    80006214:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006218:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000621c:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006220:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006224:	6794                	ld	a3,8(a5)
    80006226:	0026d703          	lhu	a4,2(a3)
    8000622a:	8b1d                	andi	a4,a4,7
    8000622c:	0706                	slli	a4,a4,0x1
    8000622e:	96ba                	add	a3,a3,a4
    80006230:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006234:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006238:	6798                	ld	a4,8(a5)
    8000623a:	00275783          	lhu	a5,2(a4)
    8000623e:	2785                	addiw	a5,a5,1
    80006240:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006244:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006248:	100017b7          	lui	a5,0x10001
    8000624c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006250:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    80006254:	0001c917          	auipc	s2,0x1c
    80006258:	da490913          	addi	s2,s2,-604 # 80021ff8 <disk+0x128>
  while(b->disk == 1) {
    8000625c:	4485                	li	s1,1
    8000625e:	00b79c63          	bne	a5,a1,80006276 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006262:	85ca                	mv	a1,s2
    80006264:	8556                	mv	a0,s5
    80006266:	ffffc097          	auipc	ra,0xffffc
    8000626a:	e00080e7          	jalr	-512(ra) # 80002066 <sleep>
  while(b->disk == 1) {
    8000626e:	004aa783          	lw	a5,4(s5)
    80006272:	fe9788e3          	beq	a5,s1,80006262 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006276:	f8042903          	lw	s2,-128(s0)
    8000627a:	00290713          	addi	a4,s2,2
    8000627e:	0712                	slli	a4,a4,0x4
    80006280:	0001c797          	auipc	a5,0x1c
    80006284:	c5078793          	addi	a5,a5,-944 # 80021ed0 <disk>
    80006288:	97ba                	add	a5,a5,a4
    8000628a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000628e:	0001c997          	auipc	s3,0x1c
    80006292:	c4298993          	addi	s3,s3,-958 # 80021ed0 <disk>
    80006296:	00491713          	slli	a4,s2,0x4
    8000629a:	0009b783          	ld	a5,0(s3)
    8000629e:	97ba                	add	a5,a5,a4
    800062a0:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800062a4:	854a                	mv	a0,s2
    800062a6:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800062aa:	00000097          	auipc	ra,0x0
    800062ae:	b9c080e7          	jalr	-1124(ra) # 80005e46 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800062b2:	8885                	andi	s1,s1,1
    800062b4:	f0ed                	bnez	s1,80006296 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800062b6:	0001c517          	auipc	a0,0x1c
    800062ba:	d4250513          	addi	a0,a0,-702 # 80021ff8 <disk+0x128>
    800062be:	ffffb097          	auipc	ra,0xffffb
    800062c2:	9cc080e7          	jalr	-1588(ra) # 80000c8a <release>
}
    800062c6:	70e6                	ld	ra,120(sp)
    800062c8:	7446                	ld	s0,112(sp)
    800062ca:	74a6                	ld	s1,104(sp)
    800062cc:	7906                	ld	s2,96(sp)
    800062ce:	69e6                	ld	s3,88(sp)
    800062d0:	6a46                	ld	s4,80(sp)
    800062d2:	6aa6                	ld	s5,72(sp)
    800062d4:	6b06                	ld	s6,64(sp)
    800062d6:	7be2                	ld	s7,56(sp)
    800062d8:	7c42                	ld	s8,48(sp)
    800062da:	7ca2                	ld	s9,40(sp)
    800062dc:	7d02                	ld	s10,32(sp)
    800062de:	6de2                	ld	s11,24(sp)
    800062e0:	6109                	addi	sp,sp,128
    800062e2:	8082                	ret

00000000800062e4 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800062e4:	1101                	addi	sp,sp,-32
    800062e6:	ec06                	sd	ra,24(sp)
    800062e8:	e822                	sd	s0,16(sp)
    800062ea:	e426                	sd	s1,8(sp)
    800062ec:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800062ee:	0001c497          	auipc	s1,0x1c
    800062f2:	be248493          	addi	s1,s1,-1054 # 80021ed0 <disk>
    800062f6:	0001c517          	auipc	a0,0x1c
    800062fa:	d0250513          	addi	a0,a0,-766 # 80021ff8 <disk+0x128>
    800062fe:	ffffb097          	auipc	ra,0xffffb
    80006302:	8d8080e7          	jalr	-1832(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006306:	10001737          	lui	a4,0x10001
    8000630a:	533c                	lw	a5,96(a4)
    8000630c:	8b8d                	andi	a5,a5,3
    8000630e:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006310:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006314:	689c                	ld	a5,16(s1)
    80006316:	0204d703          	lhu	a4,32(s1)
    8000631a:	0027d783          	lhu	a5,2(a5)
    8000631e:	04f70863          	beq	a4,a5,8000636e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006322:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006326:	6898                	ld	a4,16(s1)
    80006328:	0204d783          	lhu	a5,32(s1)
    8000632c:	8b9d                	andi	a5,a5,7
    8000632e:	078e                	slli	a5,a5,0x3
    80006330:	97ba                	add	a5,a5,a4
    80006332:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006334:	00278713          	addi	a4,a5,2
    80006338:	0712                	slli	a4,a4,0x4
    8000633a:	9726                	add	a4,a4,s1
    8000633c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006340:	e721                	bnez	a4,80006388 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006342:	0789                	addi	a5,a5,2
    80006344:	0792                	slli	a5,a5,0x4
    80006346:	97a6                	add	a5,a5,s1
    80006348:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000634a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000634e:	ffffc097          	auipc	ra,0xffffc
    80006352:	d7c080e7          	jalr	-644(ra) # 800020ca <wakeup>

    disk.used_idx += 1;
    80006356:	0204d783          	lhu	a5,32(s1)
    8000635a:	2785                	addiw	a5,a5,1
    8000635c:	17c2                	slli	a5,a5,0x30
    8000635e:	93c1                	srli	a5,a5,0x30
    80006360:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006364:	6898                	ld	a4,16(s1)
    80006366:	00275703          	lhu	a4,2(a4)
    8000636a:	faf71ce3          	bne	a4,a5,80006322 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000636e:	0001c517          	auipc	a0,0x1c
    80006372:	c8a50513          	addi	a0,a0,-886 # 80021ff8 <disk+0x128>
    80006376:	ffffb097          	auipc	ra,0xffffb
    8000637a:	914080e7          	jalr	-1772(ra) # 80000c8a <release>
}
    8000637e:	60e2                	ld	ra,24(sp)
    80006380:	6442                	ld	s0,16(sp)
    80006382:	64a2                	ld	s1,8(sp)
    80006384:	6105                	addi	sp,sp,32
    80006386:	8082                	ret
      panic("virtio_disk_intr status");
    80006388:	00002517          	auipc	a0,0x2
    8000638c:	54850513          	addi	a0,a0,1352 # 800088d0 <syscalls+0x3e8>
    80006390:	ffffa097          	auipc	ra,0xffffa
    80006394:	1b0080e7          	jalr	432(ra) # 80000540 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
