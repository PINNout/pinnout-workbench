
matmul.o:     file format elf32-littleriscv


Disassembly of section .text:

00000000 <matmul>:
   0:	715d                	addi	sp,sp,-80
   2:	c686                	sw	ra,76(sp)
   4:	c4a2                	sw	s0,72(sp)
   6:	0880                	addi	s0,sp,80
   8:	faa42e23          	sw	a0,-68(s0)
   c:	fab42c23          	sw	a1,-72(s0)
  10:	fac42a23          	sw	a2,-76(s0)
  14:	00000793          	li	a5,0
  18:	fcf41d23          	sh	a5,-38(s0)
  1c:	fc042a23          	sw	zero,-44(s0)
  20:	47c1                	li	a5,16
  22:	fcf42823          	sw	a5,-48(s0)
  26:	4785                	li	a5,1
  28:	fcf42623          	sw	a5,-52(s0)
  2c:	fd442783          	lw	a5,-44(s0)
  30:	fef42623          	sw	a5,-20(s0)
  34:	a881                	j	84 <.L2>

00000036 <.L5>:
  36:	fd442783          	lw	a5,-44(s0)
  3a:	fef42423          	sw	a5,-24(s0)
  3e:	a035                	j	6a <.L3>

00000040 <.L4>:
  40:	fec42783          	lw	a5,-20(s0)
  44:	0796                	slli	a5,a5,0x5
  46:	fb442703          	lw	a4,-76(s0)
  4a:	973e                	add	a4,a4,a5
  4c:	fe842783          	lw	a5,-24(s0)
  50:	0786                	slli	a5,a5,0x1
  52:	97ba                	add	a5,a5,a4
  54:	fda45703          	lhu	a4,-38(s0)
  58:	00e79023          	sh	a4,0(a5)
  5c:	fe842703          	lw	a4,-24(s0)
  60:	fcc42783          	lw	a5,-52(s0)
  64:	97ba                	add	a5,a5,a4
  66:	fef42423          	sw	a5,-24(s0)

0000006a <.L3>:
  6a:	fe842703          	lw	a4,-24(s0)
  6e:	fd042783          	lw	a5,-48(s0)
  72:	fcf767e3          	bltu	a4,a5,40 <.L4>
  76:	fec42703          	lw	a4,-20(s0)
  7a:	fcc42783          	lw	a5,-52(s0)
  7e:	97ba                	add	a5,a5,a4
  80:	fef42623          	sw	a5,-20(s0)

00000084 <.L2>:
  84:	fec42703          	lw	a4,-20(s0)
  88:	fd042783          	lw	a5,-48(s0)
  8c:	faf765e3          	bltu	a4,a5,36 <.L5>
  90:	fd442783          	lw	a5,-44(s0)
  94:	fef42223          	sw	a5,-28(s0)
  98:	a201                	j	198 <.L6>

0000009a <.L11>:
  9a:	fd442783          	lw	a5,-44(s0)
  9e:	fef42023          	sw	a5,-32(s0)
  a2:	a8f1                	j	17e <.L7>

000000a4 <.L10>:
  a4:	fd442783          	lw	a5,-44(s0)
  a8:	fcf42e23          	sw	a5,-36(s0)
  ac:	a865                	j	164 <.L8>

000000ae <.L9>:
  ae:	fe442783          	lw	a5,-28(s0)
  b2:	0796                	slli	a5,a5,0x5
  b4:	fbc42703          	lw	a4,-68(s0)
  b8:	973e                	add	a4,a4,a5
  ba:	fdc42783          	lw	a5,-36(s0)
  be:	0786                	slli	a5,a5,0x1
  c0:	97ba                	add	a5,a5,a4
  c2:	0007d783          	lhu	a5,0(a5)
  c6:	fcf41523          	sh	a5,-54(s0)
  ca:	fdc42783          	lw	a5,-36(s0)
  ce:	0796                	slli	a5,a5,0x5
  d0:	fb842703          	lw	a4,-72(s0)
  d4:	973e                	add	a4,a4,a5
  d6:	fe042783          	lw	a5,-32(s0)
  da:	0786                	slli	a5,a5,0x1
  dc:	97ba                	add	a5,a5,a4
  de:	0007d783          	lhu	a5,0(a5)
  e2:	fcf41423          	sh	a5,-56(s0)
  e6:	fe442783          	lw	a5,-28(s0)
  ea:	0796                	slli	a5,a5,0x5
  ec:	fb442703          	lw	a4,-76(s0)
  f0:	973e                	add	a4,a4,a5
  f2:	fe042783          	lw	a5,-32(s0)
  f6:	0786                	slli	a5,a5,0x1
  f8:	97ba                	add	a5,a5,a4
  fa:	0007d783          	lhu	a5,0(a5)
  fe:	fcf41323          	sh	a5,-58(s0)
 102:	fca45783          	lhu	a5,-54(s0)
 106:	40278753          	fcvt.s.h	a4,a5
 10a:	fc845783          	lhu	a5,-56(s0)
 10e:	402787d3          	fcvt.s.h	a5,a5
 112:	10f777d3          	fmul.s	a5,a4,a5
 116:	4407f7d3          	fcvt.h.s	a5,a5
 11a:	fcf41223          	sh	a5,-60(s0)
 11e:	fc645783          	lhu	a5,-58(s0)
 122:	40278753          	fcvt.s.h	a4,a5
 126:	fc445783          	lhu	a5,-60(s0)
 12a:	402787d3          	fcvt.s.h	a5,a5
 12e:	00f777d3          	fadd.s	a5,a4,a5
 132:	4407f7d3          	fcvt.h.s	a5,a5
 136:	fcf41123          	sh	a5,-62(s0)
 13a:	fe442783          	lw	a5,-28(s0)
 13e:	0796                	slli	a5,a5,0x5
 140:	fb442703          	lw	a4,-76(s0)
 144:	973e                	add	a4,a4,a5
 146:	fe042783          	lw	a5,-32(s0)
 14a:	0786                	slli	a5,a5,0x1
 14c:	97ba                	add	a5,a5,a4
 14e:	fc245703          	lhu	a4,-62(s0)
 152:	00e79023          	sh	a4,0(a5)
 156:	fdc42703          	lw	a4,-36(s0)
 15a:	fcc42783          	lw	a5,-52(s0)
 15e:	97ba                	add	a5,a5,a4
 160:	fcf42e23          	sw	a5,-36(s0)

00000164 <.L8>:
 164:	fdc42703          	lw	a4,-36(s0)
 168:	fd042783          	lw	a5,-48(s0)
 16c:	f4f761e3          	bltu	a4,a5,ae <.L9>
 170:	fe042703          	lw	a4,-32(s0)
 174:	fcc42783          	lw	a5,-52(s0)
 178:	97ba                	add	a5,a5,a4
 17a:	fef42023          	sw	a5,-32(s0)

0000017e <.L7>:
 17e:	fe042703          	lw	a4,-32(s0)
 182:	fd042783          	lw	a5,-48(s0)
 186:	f0f76fe3          	bltu	a4,a5,a4 <.L10>
 18a:	fe442703          	lw	a4,-28(s0)
 18e:	fcc42783          	lw	a5,-52(s0)
 192:	97ba                	add	a5,a5,a4
 194:	fef42223          	sw	a5,-28(s0)

00000198 <.L6>:
 198:	fe442703          	lw	a4,-28(s0)
 19c:	fd042783          	lw	a5,-48(s0)
 1a0:	eef76de3          	bltu	a4,a5,9a <.L11>
 1a4:	0001                	nop
 1a6:	40b6                	lw	ra,76(sp)
 1a8:	4426                	lw	s0,72(sp)
 1aa:	6161                	addi	sp,sp,80
 1ac:	8082                	ret
