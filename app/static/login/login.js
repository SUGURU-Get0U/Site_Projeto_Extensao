const BotaoMenu = document.getElementById("BotaoMenu");
const Barra_lateral = document.getElementById("Barra_lateral");
const Barra_lateral_voltar = document.getElementById("Barra_lateral_voltar");

BotaoMenu.addEventListener("click", () => {
    Barra_lateral.classList.toggle("Ativo");
});

Barra_lateral_voltar.addEventListener("click", () => {
    Barra_lateral.classList.remove("Ativo");
});