import os
import unittest

os.environ.setdefault("DATABASE_URL", "sqlite:///:memory:")

from app.app import app, bcrypt, db
from app.models import Paciente, Role, Usuario


class AuthFlowTests(unittest.TestCase):
    def setUp(self):
        app.config.update(TESTING=True, SQLALCHEMY_DATABASE_URI="sqlite:///:memory:")
        self.client = app.test_client()
        with app.app_context():
            db.drop_all()
            db.create_all()

    def test_cadastro_e_login_paciente(self):
        response = self.client.post(
            "/cadastro",
            data={
                "tipo_de_usuario": "paciente",
                "nome": "Maria Teste",
                "cpf": "12345678900",
                "email": "maria@teste.com",
                "telefone": "41999999999",
                "data_nascimento": "2000-01-15",
                "senha": "123456",
            },
            follow_redirects=True,
        )
        self.assertEqual(response.status_code, 200)

        with app.app_context():
            usuario = Usuario.query.filter_by(email="maria@teste.com").first()
            paciente = Paciente.query.filter_by(cpf_hash=Paciente.hash_cpf("12345678900")).first()
            self.assertIsNotNone(usuario)
            self.assertIsNotNone(paciente)
            self.assertEqual(usuario.paciente_id, paciente.id)

        login_response = self.client.post(
            "/login",
            data={"cpf": "12345678900", "senha": "123456"},
            follow_redirects=True,
        )
        self.assertEqual(login_response.status_code, 200)
        self.assertNotIn(b"CPF ou senha inv\u00e1lidos", login_response.get_data())

    def test_login_email_redireciona_para_menu_interno(self):
        with app.app_context():
            usuario = Usuario(
                role_id=Role.PROFISSIONAL,
                nome_completo="Profissional Teste",
                email="prof@teste.com",
                senha_hash=bcrypt.generate_password_hash("123456").decode("utf-8"),
                ativo=True,
                email_verificado=True,
            )
            db.session.add(usuario)
            db.session.commit()

        response = self.client.post(
            "/login2",
            data={"email": "prof@teste.com", "senha": "123456"},
            follow_redirects=False,
        )

        self.assertEqual(response.status_code, 302)
        self.assertEqual(response.headers.get("Location"), "/interno")

    def test_link_entrar_aponta_para_login_quando_nao_autenticado(self):
        response = self.client.get("/index", follow_redirects=False)
        self.assertEqual(response.status_code, 200)
        self.assertIn('href="/login2"', response.get_data(as_text=True))


if __name__ == "__main__":
    unittest.main()
