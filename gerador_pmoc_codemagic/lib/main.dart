import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:open_filex/open_filex.dart';

void main() => runApp(const PMOCApp());

class PMOCApp extends StatelessWidget {
  const PMOCApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gerador PMOC',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal), useMaterial3: true),
      home: const FormWizard(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Empresa { String nome='AD Climatização', cnpj='', endereco='', telefone='', email=''; }
class Cliente { String nome='', cnpjCpf='', endereco='', telefone='', email='', edificacao='', tipoUso=''; }
class MedicoesAr { String temperatura='', umidade='', co2='', particulas=''; }
class Equipamento { String descricao='', localInstalacao='', capacidade='', fabricante='', modelo='', numeroSerie=''; }
class FrequenciaAtividades { String frequencia='Mensal'; List<String> atividades=[]; }
class ResponsavelTecnico { String nome='', funcao='', creaArt=''; }

class PMOCData {
  final empresa = Empresa();
  final cliente = Cliente();
  final medicoes = MedicoesAr();
  final equipamentos = <Equipamento>[Equipamento()];
  final freq = FrequenciaAtividades();
  final resp = ResponsavelTecnico();
  void addEquip() => equipamentos.add(Equipamento());
  void removeEquip(int i){ if(equipamentos.length>1) equipamentos.removeAt(i); }
}

class FormWizard extends StatefulWidget { const FormWizard({super.key}); @override State<FormWizard> createState()=>_FormWizardState(); }
class _FormWizardState extends State<FormWizard>{
  final pmoc = PMOCData();
  int step=0;

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: const Text('Gerador PMOC')),
      body: Stepper(
        currentStep: step,
        onStepContinue: (){ if(step<6) setState(()=>step++); },
        onStepCancel: (){ if(step>0) setState(()=>step--); },
        steps: [
          Step(title: const Text('Empresa'), content: Column(children: [
            _field('Nome da empresa', (v)=>pmoc.empresa.nome=v, initial: 'AD Climatização'),
            _field('CNPJ', (v)=>pmoc.empresa.cnpj=v),
            _field('Endereço', (v)=>pmoc.empresa.endereco=v),
            _field('Telefone', (v)=>pmoc.empresa.telefone=v),
            _field('Email', (v)=>pmoc.empresa.email=v),
          ])),
          Step(title: const Text('Cliente/Edificação'), content: Column(children: [
            _field('Nome/Razão Social', (v)=>pmoc.cliente.nome=v),
            _field('CNPJ/CPF', (v)=>pmoc.cliente.cnpjCpf=v),
            _field('Edificação', (v)=>pmoc.cliente.edificacao=v),
            _field('Endereço', (v)=>pmoc.cliente.endereco=v),
            _field('Tipo de uso', (v)=>pmoc.cliente.tipoUso=v),
            _field('Telefone', (v)=>pmoc.cliente.telefone=v),
            _field('Email', (v)=>pmoc.cliente.email=v),
          ])),
          Step(title: const Text('Medições do Ar'), content: Column(children: [
            _field('Temperatura (°C)', (v)=>pmoc.medicoes.temperatura=v),
            _field('Umidade Relativa (%)', (v)=>pmoc.medicoes.umidade=v),
            _field('CO₂ (ppm)', (v)=>pmoc.medicoes.co2=v),
            _field('Partículas', (v)=>pmoc.medicoes.particulas=v),
          ])),
          Step(title: const Text('Equipamentos'), content: Column(children: [
            ...pmoc.equipamentos.asMap().entries.map((e){
              final i=e.key; final eq=e.value;
              return Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(children: [
                  Row(children:[Text('Equipamento ${i+1}'), const Spacer(),
                    IconButton(onPressed: ()=>setState(()=>pmoc.removeEquip(i)), icon: const Icon(Icons.delete_outline))]),
                  _field('Descrição', (v)=>eq.descricao=v),
                  _field('Local de instalação', (v)=>eq.localInstalacao=v),
                  _field('Capacidade (TR/BTU/h)', (v)=>eq.capacidade=v),
                  _field('Fabricante', (v)=>eq.fabricante=v),
                  _field('Modelo', (v)=>eq.modelo=v),
                  _field('Nº de Série', (v)=>eq.numeroSerie=v),
                ]),
              ));
            }),
            Align(alignment: Alignment.centerRight, child: OutlinedButton.icon(
              onPressed:()=>setState(()=>pmoc.addEquip()),
              icon: const Icon(Icons.add), label: const Text('Adicionar equipamento')))
          ])),
          Step(title: const Text('Frequência/Atividades'), content: Column(children: [
            DropdownButtonFormField<String>(
              value: pmoc.freq.frequencia,
              items: const ['Mensal','Bimestral','Trimestral','Semestral','Anual']
                .map((e)=>DropdownMenuItem(value:e, child: Text(e))).toList(),
              onChanged: (v)=>setState(()=>pmoc.freq.frequencia=v??'Mensal'),
              decoration: const InputDecoration(labelText: 'Frequência'),
            ),
            const SizedBox(height:8),
            _field('Atividades (uma por linha)', (v)=>pmoc.freq.atividades = v.split('\\n').where((e)=>e.trim().isNotEmpty).toList(), maxLines:6),
          ])),
          Step(title: const Text('Responsável Técnico'), content: Column(children: [
            _field('Nome', (v)=>pmoc.resp.nome=v),
            _field('Função', (v)=>pmoc.resp.funcao=v),
            _field('CREA/ART', (v)=>pmoc.resp.creaArt=v),
          ])),
          Step(title: const Text('Prévia e PDF'), content: Preview(pmoc: pmoc)),
        ],
      ),
    );
  }

  Widget _field(String label, void Function(String) onChanged, {String? initial, int maxLines=1}){
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextFormField(
        initialValue: initial,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        onChanged: onChanged,
      ),
    );
  }
}

class Preview extends StatefulWidget{
  final PMOCData pmoc;
  const Preview({super.key, required this.pmoc});
  @override State<Preview> createState()=>_PreviewState();
}

class _PreviewState extends State<Preview>{
  late Future<Uint8List> _pdf;
  @override void initState(){ super.initState(); _pdf = _buildPdf(widget.pmoc); }

  @override
  Widget build(BuildContext context){
    return Column(children:[
      SizedBox(
        height: 420,
        child: PdfPreview(build: (fmt) async => await _pdf, canChangePageFormat: false),
      ),
      const SizedBox(height: 8),
      FilledButton.icon(
        onPressed: () async {
          final bytes = await _pdf;
          final path = await _savePdf(bytes);
          if(!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF salvo em: $path')));
          await OpenFilex.open(path);
        },
        icon: const Icon(Icons.save_alt),
        label: const Text('Salvar e abrir PDF'),
      ),
    ]);
  }

  Future<Uint8List> _buildPdf(PMOCData pmoc) async {
    final pdf = pw.Document();
    final date = DateFormat('dd/MM/yyyy').format(DateTime.now());

    final logoBytes = (await rootBundle.load('assets/logo.png')).buffer.asUint8List();
    final logo = pw.MemoryImage(logoBytes);

    final pageTheme = pw.PageTheme(
      margin: const pw.EdgeInsets.all(28),
      buildBackground: (ctx) => pw.Center(
        child: pw.Opacity(
          opacity: 0.10, // marca d'água central grande e transparente
          child: pw.Image(logo, width: 360),
        ),
      ),
    );

    pdf.addPage(pw.Page(
      pageTheme: pageTheme,
      build: (ctx)=> pw.Column(children:[
        pw.SizedBox(height: 24),
        pw.Image(logo, width: 160),
        pw.SizedBox(height: 16),
        pw.Text('Plano de Manutenção, Operação e Controle – PMOC',
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
        pw.SizedBox(height: 16),
        _kv({'Empresa Responsável': pmoc.empresa.nome, 'CNPJ': pmoc.empresa.cnpj,
             'Cliente/Contratante': pmoc.cliente.nome, 'Edificação': pmoc.cliente.edificacao,
             'Endereço': pmoc.cliente.endereco, 'Tipo de uso': pmoc.cliente.tipoUso, 'Data': date}),
      ]),
    ));

    pdf.addPage(pw.MultiPage(
      pageTheme: pageTheme,
      header: (ctx)=> pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children:[
        pw.Row(children:[pw.Container(width:16,height:16,child: pw.Image(logo)), pw.SizedBox(width:6), pw.Text('AD Climatização – PMOC', style: const pw.TextStyle(fontSize:10))]),
        pw.Text('Data: $date', style: const pw.TextStyle(fontSize:10)),
      ]),
      footer: (ctx)=> pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children:[
        pw.Container(width:16,height:16,child: pw.Image(logo)),
        pw.Text('Página ${ctx.pageNumber}/${ctx.pagesCount}', style: const pw.TextStyle(fontSize:10)),
      ]),
      build: (ctx)=>[
        _h2('1. Empresa Responsável'),
        _kv({'Nome': pmoc.empresa.nome, 'CNPJ': pmoc.empresa.cnpj, 'Endereço': pmoc.empresa.endereco,
             'Telefone': pmoc.empresa.telefone, 'Email': pmoc.empresa.email}),
        _h2('2. Cliente / Edificação'),
        _kv({'Nome/Razão Social': pmoc.cliente.nome, 'CNPJ/CPF': pmoc.cliente.cnpjCpf, 'Edificação': pmoc.cliente.edificacao,
             'Endereço': pmoc.cliente.endereco, 'Tipo de uso': pmoc.cliente.tipoUso, 'Telefone': pmoc.cliente.telefone, 'Email': pmoc.cliente.email}),
        _h2('3. Medições da Qualidade do Ar'),
        _kv({'Temperatura (°C)': pmoc.medicoes.temperatura, 'Umidade Relativa (%)': pmoc.medicoes.umidade,
             'CO₂ (ppm)': pmoc.medicoes.co2, 'Partículas': pmoc.medicoes.particulas}),
        _h2('4. Inventário dos Equipamentos'),
        _equipTable(pmoc.equipamentos),
        _h2('5. Frequência e Atividades de Manutenção'),
        _kv({'Frequência padrão': pmoc.freq.frequencia}),
        _bullets(pmoc.freq.atividades.isEmpty? ['(Nenhuma atividade informada)'] : pmoc.freq.atividades),
        _h2('6. Responsável Técnico'),
        _kv({'Nome': pmoc.resp.nome, 'Função': pmoc.resp.funcao, 'CREA/ART': pmoc.resp.creaArt}),
        _h2('7. Assinaturas'),
        _sign(pmoc),
      ],
    ));

    return pdf.save();
  }

  pw.Widget _h2(String t)=> pw.Padding(padding: const pw.EdgeInsets.only(top:8,bottom:4), child:
    pw.Text(t, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)));

  pw.Widget _kv(Map<String,String> m){
    final header = pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white);
    final rows = <pw.TableRow>[];
    m.forEach((k,v){ rows.add(pw.TableRow(children:[
      pw.Container(color: PdfColors.blue, padding: const pw.EdgeInsets.all(6), child: pw.Text(k, style: header)),
      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(v.isEmpty? '-' : v)),
    ]));});
    return pw.Table(
      border: pw.TableBorder.all(width:0.5, color: PdfColors.grey500),
      columnWidths: {0: const pw.FlexColumnWidth(2), 1: const pw.FlexColumnWidth(5)},
      children: rows,
    );
  }

  pw.Widget _equipTable(List<Equipamento> eqs){
    final headers = ['Descrição','Local','Capacidade','Fabricante','Modelo','Nº Série'];
    final head = pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.blue),
      children: headers.map((h)=> pw.Padding(padding: const pw.EdgeInsets.all(6),
        child: pw.Text(h, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white)))).toList(),
    );
    final rows = eqs.map((e)=> pw.TableRow(children:[
      _cell(e.descricao), _cell(e.localInstalacao), _cell(e.capacidade),
      _cell(e.fabricante), _cell(e.modelo), _cell(e.numeroSerie),
    ])).toList();
    return pw.Table(
      border: pw.TableBorder.all(width:0.5, color: PdfColors.grey500),
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      columnWidths: const {0: pw.FlexColumnWidth(2),1: pw.FlexColumnWidth(2),2: pw.FlexColumnWidth(1.5),3: pw.FlexColumnWidth(1.5),4: pw.FlexColumnWidth(1.5),5: pw.FlexColumnWidth(1.5)},
      children: [head, ...rows],
    );
  }
  pw.Widget _cell(String t)=> pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(t.isEmpty? '-' : t));

  pw.Widget _bullets(List<String> items)=> pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: items.map((e)=> pw.Bullet(text: e)).toList()
  );

  pw.Widget _sign(PMOCData pmoc)=> pw.Column(children:[
    pw.SizedBox(height: 24),
    pw.Container(height: 0.8, width: double.infinity, color: PdfColors.grey700),
    pw.SizedBox(height: 4),
    pw.Text('Responsável Técnico – ${pmoc.resp.nome.isEmpty? "________________" : pmoc.resp.nome}  |  CREA/ART: ${pmoc.resp.creaArt.isEmpty? "________" : pmoc.resp.creaArt}', style: const pw.TextStyle(fontSize: 10)),
    pw.SizedBox(height: 18),
    pw.Container(height: 0.8, width: double.infinity, color: PdfColors.grey700),
    pw.SizedBox(height: 4),
    pw.Text('Assinatura do Cliente/Contratante', style: const pw.TextStyle(fontSize: 10)),
  ]);

  Future<String> _savePdf(Uint8List bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/PMOC_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}