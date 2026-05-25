# Calculadora x86-64

**Disciplina:** Programação para Interfaceamento de Hardware e Software  
**Instituição:** Universidade Estadual de Maringá 
**Dupla:**
- Nome: Letícia Akemi Nakahati Vieira - RA: 140535
- Nome: Pedro Henrique Pereira da Silva - RA: 

---

## Descrição

Trabalho 1 da disciplina:
Calculadora implementada em linguagem assembly x86-64 com sintaxe AT&T (GAS), sem uso da biblioteca C (libc). Toda a entrada e saída é feita diretamente via syscalls do Linux. O programa aceita operandos reais e realiza operações aritméticas, combinatórias e matemáticas, exibindo o resultado e perguntando se o usuário deseja continuar.

Trabalho 2 da disciplina:

Foi escolhido a realização de ambas as partes sem o uso da Libc, considerando que o trabalho 2 não permitiria esse uso

---

## Operações suportadas

| Operador | Operação | Operandos |
|----------|----------|-----------|
| `+` | Soma | dois |
| `-` | Subtração | dois |
| `*` | Multiplicação | dois |
| `/` | Divisão | dois |
| `^` | Exponenciação (base ^ expoente) | dois |
| `c` | Combinação simples C(n, r) | dois |
| `a` | Arranjo simples A(n, r) | dois |
| `l` | Logaritmo (1º operando na base do 2º) | dois |
| `!` | Fatorial | um |
| `i` | Inverso (1 ÷ número) | um |
| `r` | Raiz quadrada | um |
| `p` | Próximo primo ≥ número | um |

---

## Validações

- **Divisão:** informa erro se o divisor for zero.
- **Fatorial, combinação e arranjo:** informa erro se algum operando for negativo ou não inteiro.
- **Combinação e arranjo:** informa erro se n < r.
- **Raiz quadrada:** informa erro se o operando for negativo.
- **Inverso:** informa erro se o operando for zero.
- **Logaritmo:** informa erro se o logaritmando for ≤ 0 ou se a base for ≤ 0 ou igual a 1.

---

## Requisitos

- Linux x86-64
- GAS (GNU Assembler) — pacote `binutils`
- Linker `ld`

Para verificar se estão instalados:

```bash
as --version
ld --version
```

---

## Como compilar e executar

```bash
# Montar (assemblar)
as -o calculadora.o calculadora.s

# Linkar
ld -o calculadora calculadora.o

# Executar
./calculadora
```

---

## Exemplos de uso

```
Digite o primeiro operando: 10
Digite o operador: +
Digite o segundo operando: 5
Resultado: 15

Continuar? (s/n): s

Digite o primeiro operando: 9
Digite o operador: r
Resultado: 3

Continuar? (s/n): s

Digite o primeiro operando: 5
Digite o operador: !
Resultado: 120

Continuar? (s/n): s

Digite o primeiro operando: 10
Digite o operador: c
Digite o segundo operando: 3
Resultado: 120

Continuar? (s/n): s

Digite o primeiro operando: 100
Digite o operador: l
Digite o segundo operando: 10
Resultado: 2

Continuar? (s/n): n
```

---


