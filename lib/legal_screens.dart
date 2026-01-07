import 'package:flutter/material.dart';

class LegalPageLayout extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const LegalPageLayout({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: const Color(0xFF667eea)),
              ),
            ),
            const SizedBox(height: 24),
            ...children,
            const SizedBox(height: 40),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('Entendi e Voltar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2D3748),
        ),
      ),
    );
  }
}

class SectionText extends StatelessWidget {
  final String text;
  const SectionText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        height: 1.6,
        color: Colors.grey[700],
      ),
      textAlign: TextAlign.justify,
    );
  }
}

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalPageLayout(
      title: 'Termos de Uso',
      icon: Icons.gavel,
      children: [
        SectionTitle('1. Aceitação dos Termos'),
        SectionText(
          'Ao criar uma conta ou usar o Par Cristão, você concorda em cumprir estes Termos de Uso. Se você não concordar com qualquer parte destes termos, não deverá usar nosso serviço.',
        ),
        SectionTitle('2. Elegibilidade'),
        SectionText(
          'Você deve ter pelo menos 18 anos de idade para usar este aplicativo. Ao usar o serviço, você declara e garante que tem o direito, autoridade e capacidade para celebrar este contrato.',
        ),
        SectionTitle('3. Conduta do Usuário'),
        SectionText(
          'Esperamos que todos os usuários mantenham um comportamento respeitoso e cristão. É proibido:\n'
          '• Assediar ou intimidar outros usuários.\n'
          '• Publicar conteúdo ofensivo, obsceno ou ilegal.\n'
          '• Usar o serviço para fins comerciais não autorizados.\n'
          '• Criar perfis falsos ou se passar por outra pessoa.',
        ),
        SectionTitle('4. Rescisão'),
        SectionText(
          'Reservamo-nos o direito de suspender ou encerrar sua conta a qualquer momento, sem aviso prévio, se acreditarmos que você violou estes Termos.',
        ),
        SectionTitle('5. Isenção de Responsabilidade'),
        SectionText(
          'O serviço é fornecido "como está". Não garantimos que o serviço será ininterrupto ou livre de erros.\n\n'
          'IMPORTANTE: Não nos responsabilizamos pela veracidade das informações fornecidas por outros usuários. Não realizamos verificação de antecedentes criminais. Você é o único responsável por suas interações e deve ter cautela ao compartilhar informações pessoais. Não nos responsabilizamos por qualquer engano, dano ou prejuízo decorrente de interações com outros usuários.',
        ),
        SectionTitle('6. Selo de Verificação'),
        SectionText(
          'O selo de verificação (ícone azul ao lado do nome) indica que o usuário passou por um processo de verificação de identidade através de selfie com gesto.\n\n'
          'IMPORTANTE:\n'
          '• Apenas perfis com o selo de verificação foram verificados.\n'
          '• Perfis SEM o selo não passaram por verificação de identidade.\n'
          '• A verificação confirma apenas que a pessoa corresponde às fotos do perfil, NÃO garante caráter, intenções ou antecedentes.\n'
          '• Se um usuário verificado alterar suas fotos, o selo é removido automaticamente e uma nova verificação será necessária.\n\n'
          'Recomendamos cautela adicional ao interagir com perfis não verificados.',
        ),
      ],
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalPageLayout(
      title: 'Política de Privacidade',
      icon: Icons.privacy_tip_outlined,
      children: [
        SectionText(
          'Sua privacidade é muito importante para nós. Esta política descreve como coletamos, usamos e protegemos suas informações pessoais.',
        ),
        SectionTitle('1. Informações que Coletamos'),
        SectionText(
          'Coletamos informações que você nos fornece diretamente, como:\n'
          '• Dados de cadastro (nome, e-mail, data de nascimento).\n'
          '• Informações do perfil (fotos, bio, igreja, interesses).\n'
          '• Localização (para mostrar pessoas próximas).\n\n'
          'Coletamos informações sobre sua denominação religiosa estritamente para conectar você com perfis compatíveis, conforme o objetivo do aplicativo.',
        ),
        SectionTitle('2. Como Usamos Seus Dados'),
        SectionText(
          'Usamos suas informações para:\n'
          '• Operar e melhorar o serviço.\n'
          '• Conectar você com outros usuários compatíveis.\n'
          '• Enviar notificações importantes.\n'
          '• Garantir a segurança da comunidade.',
        ),
        SectionTitle('3. Compartilhamento de Informações'),
        SectionText(
          'Não vendemos seus dados pessoais. Compartilhamos informações apenas quando necessário para operar o serviço (ex: provedores de infraestrutura) ou quando exigido por lei.',
        ),
        SectionTitle('4. Segurança'),
        SectionText(
          'Implementamos medidas de segurança para proteger seus dados contra acesso não autorizado. No entanto, nenhum sistema é 100% seguro.',
        ),
        SectionTitle('5. Seus Direitos'),
        SectionText(
          'Você pode acessar, corrigir ou excluir sua conta e seus dados a qualquer momento através das configurações do aplicativo.',
        ),
        SectionTitle('6. Verificação de Perfil'),
        SectionText(
          'Oferecemos um sistema voluntário de verificação de identidade através de selfie com gesto. Ao solicitar verificação:\n\n'
          '• Você nos envia uma selfie realizando um gesto específico.\n'
          '• Comparamos a selfie com as fotos do seu perfil.\n'
          '• Se aprovado, seu perfil recebe um selo de verificação (ícone azul).\n'
          '• Se você alterar suas fotos após a verificação, o selo é removido automaticamente.\n\n'
          'A selfie de verificação é armazenada de forma segura e utilizada exclusivamente para fins de verificação de identidade.',
        ),
      ],
    );
  }
}

class SafetyTipsScreen extends StatelessWidget {
  const SafetyTipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalPageLayout(
      title: 'Dicas de Segurança',
      icon: Icons.health_and_safety_outlined,
      children: [
        SectionTitle('1. Proteja Suas Informações Financeiras'),
        SectionText(
          'Nunca envie dinheiro ou informações de cartão de crédito para ninguém que você conheceu no aplicativo. Se alguém pedir dinheiro, denuncie imediatamente.',
        ),
        SectionTitle('2. Mantenha Conversas na Plataforma'),
        SectionText(
          'Recomendamos manter as conversas dentro do aplicativo até que você se sinta confortável e seguro para trocar números de telefone.',
        ),
        SectionTitle('3. Encontros Presenciais'),
        SectionText(
          'Ao encontrar alguém pela primeira vez:\n'
          '• Escolha um local público e movimentado.\n'
          '• Avise um amigo ou familiar onde você vai.\n'
          '• Tenha seu próprio meio de transporte.\n'
          '• Confie nos seus instintos.',
        ),
        SectionTitle('4. Relate Comportamentos Suspeitos'),
        SectionText(
          'Você pode bloquear e denunciar qualquer usuário que viole nossos termos ou faça você se sentir desconfortável. Isso ajuda a manter a comunidade segura para todos.',
        ),
        SectionTitle('5. Consentimento e Respeito'),
        SectionText(
          'O respeito é fundamental. Todos os limites devem ser respeitados. Se você não se sentir confortável, tem todo o direito de encerrar a interação.',
        ),
      ],
    );
  }
}
