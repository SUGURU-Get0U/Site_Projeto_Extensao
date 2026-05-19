while True:
    genero = input("Digite o gênero (M/F): ").upper()

    if genero == "M":
        homem = True
    elif genero == "F":
        homem = False
    else:
        print("Gênero inválido. Por favor, digite 'M' para masculino ou 'F' para feminino.")

    sintomas = {
        1: {
            "nome": "Deficiência intelectual",
            "homem": 0.32,
            "mulher": 0.20
        },

        2: {
            "nome": "Face alongada/orelhas",
            "homem": 0.29,
            "mulher": 0.09
        },

        3: {
            "nome": "Macroorquidismo",
            "homem": 0.26,
            "mulher": None
        },

        4: {
            "nome": "Hipermobilidade articular",
            "homem": 0.19,
            "mulher": 0.04
        },

        5: {
            "nome": "Dificuldades de aprendizagem",
            "homem": 0.18,
            "mulher": 0.28
        },

        6: {
            "nome": "Déficit de atenção",
            "homem": 0.17,
            "mulher": 0.12
        },

        7: {
            "nome": "Movimentos repetitivos",
            "homem": 0.17,
            "mulher": 0.05
        },

        8: {
            "nome": "Atraso na fala",
            "homem": 0.14,
            "mulher": 0.01
        },

        9: {
            "nome": "Hiperatividade",
            "homem": 0.12,
            "mulher": 0.04
        },

        10: {
            "nome": "Evita contato visual",
            "homem": 0.06,
            "mulher": 0.08
        },

        11: {
            "nome": "Evita contato físico",
            "homem": 0.04,
            "mulher": 0.07
        },

        12: {
            "nome": "Agressividade",
            "homem": 0.01,
            "mulher": 0.02
        }
    }

    def fórmula_Score(score, GENERO):
        try:
            resposta = int(input("\nDigite o número do sintoma que você apresenta (ou 0 para finalizar): "))
            if resposta == 0:
                return score, True
            
            elif resposta == 3 and GENERO == "mulher":
                print("O sintoma 'Macroorquidismo' não é aplicável para mulheres. Por favor, escolha outro sintoma.")
                return score, False

            elif resposta in sintomas:
                score += sintomas[resposta][GENERO]
                return score, False
            
            else:
                print("Número de sintoma inválido. Por favor, tente novamente.")
                return score, False
        except ValueError:
                print("Entrada inválida. Por favor, digite um número.")
                return score, False

    def calcular_Score():
        x = ("-" * 55)
        score = 0.0

        if homem:
            GENERO = "homem"
            limite = 0.56

            print("\n\nSintomas para homens:\n")
            print(x)
            for id, dados in sintomas.items():
                print(f"{id:<3} | {dados['nome']:<40} | {dados['homem']}")
                print(x)
            
            Finish = False
            while not Finish:
                score, Finish = fórmula_Score(score, GENERO)
            
        else:
            GENERO = "mulher"
            limite = 0.55

            print("\n\nSintomas para mulher:\n")
            print(x)
            for id, dados in sintomas.items():
                print(f"{id:<3} | {dados['nome']:<40} | {dados['mulher']}")
                print(x)
            Finish = False
            while not Finish:
                score, Finish = fórmula_Score(score, GENERO)

        print(f"\nSeu score é: {score:.2f}")
        if score >= limite:
            print("O resultado sugere a possibilidade de Síndrome de X Frágil. Recomenda-se procurar um profissional de saúde para uma avaliação mais detalhada.")

    calcular_Score()

    fim = input("Finalizar programa? aperte 0 novamente: ")
    if fim == "0":
        break
