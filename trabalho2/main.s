.equ SYS_READ,   0
.equ SYS_WRITE,  1
.equ SYS_EXIT,   60
.equ STDIN,      0
.equ STDOUT,     1

.section .rodata
#verificar
msg_entrada:       .string "Digite a expressão sem espaço: "
msg_entrada_l = . - msg_entrada

msg_cont:         .string "Continuar? (s/n): "
msg_cont_l = . - msg_cont

msg_res:          .string "Resultado: "
msg_res_l = . - msg_res

msg_nl:           .string "\n"
msg_nl_l = . - msg_nl

msg_ponto:        .string "."
msg_sinal_menos:  .ascii "-"

.align 8
const_dez:        .double 10.0
const_um: .double 1.0

.section .bss
.global buf_entrada
.global funcoes
.global buf_op1
.global buf_op2
.global operador

buf_entrada: .space 64 # linha digitada pelo usuário
buf_out: .space 64 # buffer de saída
funcoes: .space 520 # vetor de funções (26 * 20 bytes)
buf_op1: .space 64 # buffer do operando 1
buf_op2: .space 64 # buffer do operando 2
operador: .space 4  # buffer do operador

.section .text
.global _start
.global ler_operando
.global converter_para_float
.global imprimir_string
.global exibir_resultado

_start:
    call loop_principal

    movq $SYS_EXIT, %rax
    movq $0,        %rdi
    syscall

# loop principal do programa, lê as expressões do teclado
# e decide se é uma definição (baseado no igual) ou chamada(como f(5)) e executa
loop_principal:
    pushq %rbp
    movq  %rsp, %rbp

.Lloop:
    movq $msg_entrada, %rsi
    movq $msg_entrada_l, %rdx
    call imprimir_string

    movq $buf_entrada, %rsi
    movq $64, %rdx
    call ler_teclado


    movq $buf_entrada, %rsi

.Landa_string:
    movb (%rsi), %al
    cmpb $0, %al 
    je .Lchamada #é o fim da string, e nao tem o =

    cmpb $10, %al 
    je .Lchamada # deu \n e nao tem =

    cmpb $'=', %al
    je .Ldefinicao # achou o igual

    incq %rsi
    jmp .Landa_string 

.Ldefinicao:
    call salvar_funcao
    jmp .Lperguntar_cont

.Lchamada:
    call preparar_chamada

    cmpq $2, %rax # o 2 é uma convenção pra já calculou, foi feito pra caso de operação mista
    je .Lja_calculou
    call executar_operacao

    cmpq $1, %rax
    je .Lperguntar_cont

    call exibir_resultado

    jmp .Lperguntar_cont

.Lja_calculou:
    call exibir_resultado
    jmp .Lperguntar_cont
    
.Lperguntar_cont:
    movq $msg_cont, %rsi
    movq $msg_cont_l, %rdx
    call imprimir_string

    movq $buf_entrada, %rsi
    movq $2, %rdx #le 2 bytes: caractere + /n
    call ler_teclado

    movq $buf_entrada, %rsi
    movb (%rsi), %al
    cmpb $'s', %al
    je .Lloop
    cmpb $'S', %al
    je .Lloop

    movq %rbp, %rsp
    popq %rbp
    ret

#Imprime a string no terminal
#Entrada: %rsi (endereço da string), %rdx (tamanho)
imprimir_string:
    movq $SYS_WRITE, %rax
    movq $STDOUT, %rdi
    syscall
    ret

#Faz a leitura do teclado para um buffer
#Entrada: %rsi (endereço do buffer), %rdx (tamanho máximo)
ler_teclado:
    movq $SYS_READ, %rax
    movq $STDIN, %rdi
    syscall
    ret

#Salva uma definição no vetor funcoes, atualizando ele
#Formato: byte 0 (letra do parâmetro) e o restante é a expressão
salvar_funcao:
    pushq %rbp
    movq  %rsp, %rbp
    #primeiro pega a letra da função
    movq $buf_entrada, %rsi
    movb (%rsi), %al 
    movzbq %al, %rax #zera o rax pra ficar so com o byte lido
    #calcula o indice no vetor 
    subq $'a', %rax #faz letra - a, pra achar a posicao do vetor
    imulq $20, %rax #cada parte do vetor tem 20 bytes, então multiplica por 20
    addq $funcoes, %rax #pego endereco da funcao e somo com onde ta o rax pra aponta no lugar certo
    movq %rax, %rdi #troco rax por rdi pra guarda o endereco e poder usa zero

    movq $buf_entrada, %rsi

    movb 1(%rsi), %al #lê o segundo caractere para checar se a função tem ('(')
    cmpb $'(', %al
    je .Lgrava_parametro

    movb $0, (%rdi)
    jmp .Lprepara_copia
    
.Lgrava_parametro:
    addq $2, %rsi
    movb (%rsi), %al
    movb %al, (%rdi)

.Lprepara_copia:
    incq %rdi
    
.Lproc_op:
    movb (%rsi), %al 

    cmpb $'=', %al 
    je .Lacho_igual 

    incq %rsi #se nao for, eu incremento um e recomeço o loop
    jmp .Lproc_op 
    
.Lacho_igual:
    incq %rsi #passei do igual
    
.Lloop_copia:
    movb (%rsi), %al #copia o primeiro byte e coloca no al 

    cmpb $10, %al # se for \n, ele da jump pro final do loop
    je .Lfim_loop_copia

    movb %al, (%rdi) #coloca o que tava em %al no endereco q ta rdi
    incq %rsi
    incq %rdi 
    jmp .Lloop_copia

.Lfim_loop_copia:
    movb $0, (%rdi) #coloco um \0 no final da funcao
    movq %rbp, %rsp
    popq %rbp
    ret 

#Recebe a entrada e coloca no lugar certo buf_op1 e buf_op2
#trata 3 casos: 
#variavel simples (como "a")
#chamada de funcao (como "f(4)")
#expressoes mistas (como "a+f(10)")   
preparar_chamada:
    pushq %rbp
    movq  %rsp, %rbp
    movq $buf_entrada, %rsi
    movq %rsi, %rdx 

    #f(5) ou f
.Lverifica_parent:
    movb (%rsi), %al

    cmpb $10, %al
    je .Lsem_parent 

    cmpb $0, %al
    je .Lsem_parent 

    cmpb $'(', %al
    je .Lcom_parent

    #checar se é misto, tipo a + f(10)
    cmpb $'+', %al
    je .Lexpr_mista

    cmpb $'-', %al
    je .Lexpr_mista

    cmpb $'*', %al
    je .Lexpr_mista

    cmpb $'/', %al
    je .Lexpr_mista

    cmpb $'^', %al
    je .Lexpr_mista

    incq %rsi
    jmp .Lverifica_parent
    
# aceitar só a
.Lsem_parent:
    movq $buf_entrada, %rsi
    movb (%rsi), %al
    movzbq %al, %rax
    subq $'a', %rax
    imulq $20, %rax
    addq $funcoes, %rax
    movq %rax, %rdi
    incq %rdi
    
    movq $buf_op1, %rcx
.Lcopia_sem:
    movb (%rdi), %al

    cmpb $0, %al
    je .Lfim_copia_sem

    movb %al, (%rcx)
    incq %rcx
    incq %rdi
    jmp .Lcopia_sem

.Lfim_copia_sem:
    movb $0, (%rcx)
    movb $'+', operador(%rip) #valor + 0 = valor
    movb $'0', buf_op2(%rip)
    movb $0, buf_op2+1(%rip)
    jmp .Lfinal_salva
    
.Lcom_parent:
    movq $buf_entrada, %rsi
    movb (%rsi), %al
    movzbq %al, %rax
    subq $'a', %rax
    imulq $20, %rax
    addq $funcoes, %rax
    movq %rax, %rdi

    movq $buf_entrada, %rsi

.Lloop_acha_num:
    movb (%rsi), %al 

    cmpb $'(', %al
    je .Lacho_parenteses

    incq %rsi
    jmp .Lloop_acha_num
    
.Lacho_parenteses:
    movq $buf_out, %rcx #vai pro buf_out ao inves do buf_op
    incq %rsi

.Lcopia_argumento:
    movb (%rsi), %al

    cmpb $')', %al
    je .Lcopia_op

    movb %al, (%rcx)
    incq %rcx
    incq %rsi

    jmp .Lcopia_argumento

.Lcopia_op:
    movb $0, (%rcx) 

    movb (%rdi), %r9b #guarda a letra do param pra substituir depois
    incq %rdi

    movq $buf_op1, %rcx

.Lparse_op1:
    movb (%rdi), %al

    cmpb $0, %al
    je .Lfinal_salva

    cmpb $10, %al
    je .Lfinal_salva

    cmpb $'+', %al
    je .Lachou_operador
    cmpb $'-', %al
    je .Lachou_operador
    cmpb $'*', %al
    je .Lachou_operador
    cmpb $'/', %al
    je .Lachou_operador
    cmpb $'^', %al
    je .Lachou_operador
    cmpb $'!', %al
    je .Lachou_operador
    cmpb $'c', %al
    je .Lachou_operador
    cmpb $'a', %al
    je .Lachou_operador
    cmpb $'i', %al
    je .Lachou_operador
    cmpb $'r', %al
    je .Lachou_operador
    cmpb $'l', %al
    je .Lachou_operador
    cmpb $'p', %al
    je .Lachou_operador

    cmpb %r9b, %al
    je .Lsubstitui_op1

    movb %al, (%rcx)
    incq %rcx
    incq %rdi
    jmp .Lparse_op1

.Lsubstitui_op1:
    movq $buf_out, %r10 #substitui a letra do param pelo arg salvo em buf_out

.Lloop_subst_op1:
    movb (%r10), %al
    cmpb $0, %al
    je .Lfim_subst_op1

    movb %al, (%rcx)
    incq %rcx
    incq %r10
    jmp .Lloop_subst_op1

.Lfim_subst_op1:
    incq %rdi
    jmp .Lparse_op1

.Lsubstitui_op2:
    movq $buf_out, %r10

.Lloop_subst_op2:
    movb (%r10), %al
    cmpb $0, %al
    je .Lfim_subst_op2

    movb %al, (%rcx)
    incq %rcx
    incq %r10
    jmp .Lloop_subst_op2

.Lfim_subst_op2:
    incq %rdi
    jmp .Lparse_op2
    
.Lachou_operador:
    movb $0, (%rcx)

    movb %al, operador(%rip)
    incq %rdi

    movq $buf_op2, %rcx 

.Lparse_op2:
    movb (%rdi), %al

    cmpb $0, %al
    je .Lfinal_salva
    cmpb $10, %al
    je .Lfinal_salva

    cmpb %r9b, %al
    je .Lsubstitui_op2
    
    movb %al, (%rcx)
    incq %rcx
    incq %rdi
    jmp .Lparse_op2

.Lexpr_mista:
    # a + f(10)
    movq $buf_op1, %rcx

.Lloop_mista_op1:
    movb (%rdx), %al

    cmpq %rsi, %rdx
    je .Lcopia_op_mista

    movb %al, (%rcx)    
    incq %rcx
    incq %rdx

    jmp .Lloop_mista_op1

.Lcopia_op_mista:
    movb $0, (%rcx)

    movb (%rsi), %al
    movb %al, operador(%rip)
    
    incq %rsi
    movq $buf_op2, %rcx

.Lloop_mista_op2:
    movb (%rsi), %al

    cmpb $0, %al
    je .Lfim_copia_mista

    cmpb $10, %al
    je .Lfim_copia_mista

    movb %al, (%rcx)
    incq %rcx
    incq %rsi

    jmp .Lloop_mista_op2

.Lfim_copia_mista:
    movb $0, (%rcx)

    movq $buf_op2, %rsi
    movb 1(%rsi), %al
    cmpb $'(', %al #checa se o op2 é uma função
    je .Lmista_com_funcao
    jmp .Lfinal_salva

.Lmista_com_funcao:
    movq $buf_op1, %rsi
    call resolver_operando

    movq $buf_op1, %rsi
    call ler_operando
    call converter_para_float

    subq $8, %rsp
    movsd %xmm0, (%rsp) #salva do lado esquerdo da pilha
    
    movzbq operador(%rip), %rax
    pushq %rax
    
    movq $buf_op2, %rsi
    movq $buf_entrada, %rcx

.Lcopia_pra_entrada:
    movb (%rsi), %al
    movb %al, (%rcx)

    incq %rsi
    incq %rcx

    cmpb $0, %al
    jne .Lcopia_pra_entrada

    call preparar_chamada
    call executar_operacao

    movapd %xmm0, %xmm1

    popq %rax

    movsd (%rsp), %xmm0
    addq $8, %rsp
    
    #nesse trabalho, as operações mistas faz as 4 operações básicas
    cmpb $'+', %al
    je .Lmista_soma
    cmpb $'-', %al
    je .Lmista_sub
    cmpb $'*', %al
    je .Lmista_mul
    cmpb $'/', %al
    je .Lmista_div

    jmp .Lmista_fim

.Lmista_soma:
    addsd %xmm1, %xmm0
    jmp .Lmista_fim

.Lmista_sub:
    subsd %xmm1, %xmm0
    jmp .Lmista_fim
.Lmista_mul:
    mulsd %xmm1, %xmm0
    jmp .Lmista_fim
.Lmista_div:
    divsd %xmm1, %xmm0
    jmp .Lmista_fim

.Lmista_fim:
    movq $2, %rax #coloca o 2 porque foi calculado
    movq %rbp, %rsp
    popq %rbp
    ret

.Lfinal_salva:
    movb $0, (%rcx)

    movq $buf_op1, %rsi
    call resolver_operando

    movq $buf_op2, %rsi
    call resolver_operando

    movq %rbp, %rsp
    popq %rbp
    ret

#Verifica se o buffer começa com uma letra (uma variável)
#Entrada: %rsi = endereço do buffer
#sobrescreve o buffer com o valor que a variável armazena
resolver_operando:
    pushq %rbp
    movq %rsp, %rbp

    movb (%rsi), %al

    #compara se é >= 'a' e <='z'
    cmpb $'a', %al
    jl .Lfim_resolve

    cmpb $'z', %al
    jg .Lfim_resolve

    movzbq %al, %rax
    subq $'a', %rax 
    imulq $20, %rax 
    addq $funcoes, %rax
    movq %rax, %rdi
    incq %rdi
    movq %rsi, %rcx #sobrescreve

.Lcopia_mem:
    movb (%rdi), %al

    cmpb $0, %al
    je .Lfim_copia_mem

    movb %al, (%rcx)
    incq %rcx
    incq %rdi
    
    jmp .Lcopia_mem

.Lfim_copia_mem:
    movb $0, (%rcx)

.Lfim_resolve:
    movq %rbp, %rsp
    popq %rbp
    ret

ler_operando:
    pushq %rbp
    movq  %rsp, %rbp

    movq $0, %rax
    movq $0, %rcx
    movq $0, %r8 #contador de casas decimais
    movq $0, %r9 #flag de já passou pelo decimal
    movq $0, %r10 #flag de negativo

.Ller_digito:
    movb (%rsi), %cl 

    cmpb $10, %cl
    je .Lfim_leitura

    cmpb $0, %cl
    je .Lfim_leitura

    cmpb $'-', %cl
    je .Lmarcar_negativo

    cmpb $'.', %cl
    je .Lmarcar_ponto 

    cmpq $1, %r9
    je .Lcontar_casa

    subb $'0', %cl

    imulq $10, %rax
    addq %rcx, %rax

    incq %rsi

    jmp .Ller_digito

.Lcontar_casa:
    incq %r8
    
    subb $'0', %cl
    
    imulq $10, %rax
    addq %rcx, %rax

    incq %rsi

    jmp .Ller_digito

.Lmarcar_negativo:
    incq %rsi
    incq %r10
    jmp .Ller_digito

.Lmarcar_ponto:
    incq %rsi
    incq %r9
    jmp .Ller_digito

.Lfim_leitura:
    cmpq $1, %r10
    jne .Lfim_ret
    negq %rax

.Lfim_ret:
    movq %rbp, %rsp
    popq %rbp
    ret

converter_para_float:
    pushq %rbp
    movq  %rsp, %rbp

    cvtsi2sd %rax, %xmm0
    movsd const_um(%rip), %xmm3
    movsd const_dez(%rip), %xmm2

    cmpq $0, %r8
    je .Lconverte_fim

.Lmultiplica_acc:

    mulsd %xmm2, %xmm3
    
    decq %r8
    cmpq $0, %r8
    jne .Lmultiplica_acc
    
    divsd %xmm3, %xmm0 #divide pelo acumulador para posicionar o ponto

.Lconverte_fim:
    movq %rbp, %rsp
    popq %rbp
    ret

#Imprime o resultado que saiu em %xmm0
exibir_resultado:
    pushq %rbp
    movq  %rsp, %rbp

    pushq %r12
    pushq %r13

    pushq %rax
    movq $msg_res, %rsi
    movq $msg_res_l, %rdx
    call imprimir_string
    popq %rax
    
    xorpd %xmm1, %xmm1
    ucomisd %xmm1, %xmm0
    jae .Lnum_positivo

    movq $msg_sinal_menos, %rsi
    movq $1, %rdx
    call imprimir_string

    subsd %xmm0, %xmm1
    movsd %xmm1, %xmm0

.Lnum_positivo:
    cvttsd2si %xmm0, %rax  #parte inteira do resultado
    movq %rax, %r12 #guarda para calcular a parte decimal

.print_numero:
    movq $10, %r8
    movq $buf_out, %rdi
    addq $63, %rdi

.Lconverter_digito:
    cqo
    idivq %r8
    addb $'0', %dl
    decq %rdi
    movb %dl, (%rdi)
    cmpq $0, %rax
    jne .Lconverter_digito

    movq %rdi, %rsi
    movq $buf_out, %rdx
    addq $64, %rdx
    subq %rsi, %rdx
    call imprimir_string     

    movq $msg_ponto, %rsi
    movq $1, %rdx
    call imprimir_string

    cvtsi2sd %r12, %xmm1
    subsd %xmm1, %xmm0

    movq $4, %r13

.Limprime_decimal:
    mulsd const_dez(%rip), %xmm0
    cvttsd2si %xmm0, %rax
    
    cvtsi2sd %rax, %xmm1
    subsd %xmm1, %xmm0

    addb $'0', %al
    movb %al, buf_out(%rip)
    
    movq $buf_out, %rsi
    movq $1, %rdx
    call imprimir_string

    decq %r13 

    xorpd %xmm4, %xmm4
    ucomisd %xmm4, %xmm0
    je .Lfim_deci

    jnz .Limprime_decimal

.Lfim_deci:
    movq $msg_nl, %rsi
    movq $msg_nl_l, %rdx
    call imprimir_string

    popq %r13
    popq %r12
    
    movq %rbp, %rsp
    popq %rbp
    ret
