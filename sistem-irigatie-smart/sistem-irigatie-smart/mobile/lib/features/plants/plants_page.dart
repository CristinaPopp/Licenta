import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../common/app_state.dart';

//Info pentru familii
class FamilyExtra {
  final String desc;
  final String care;
  final String uses;
  final String image; //asset path
  const FamilyExtra({
    required this.desc,
    required this.care,
    required this.uses,
    required this.image,
  });
}

const _imgDir = 'assets/families';

const Map<String, FamilyExtra> kFamilyInfo = {
  'Bromeliaceae': FamilyExtra(
    desc: 'Familie tropicală; multe epifite (ananasul este aici). Preferă lumină filtrată.',
    care: 'Pulverizare/umiditate ambientală, substrat aerat, udare moderată.',
    uses: 'Ornamentale, fructe (ananas).',
    image: '$_imgDir/bromeliaceae.jpg',
  ),
  'Betulaceae': FamilyExtra(
    desc: 'Familia mesteacănului (Betula), arin, alun.',
    care: 'Suportă frig; sol ușor acid; udare regulată la plantare.',
    uses: 'Lemn, ornamentale, nucifere (alun).',
    image: '$_imgDir/betulaceae.jpg',
  ),
  'Asteridaceae': FamilyExtra(
    desc: 'Subcladă cu multe ornamentale/utile (diverse grupuri).',
    care: 'În general soare și udare moderată.',
    uses: 'Ornamentale, medicinale.',
    image: '$_imgDir/asteridaceae.jpg',
  ),
  'Caryophyllaceae': FamilyExtra(
    desc: 'Garoafe și rude; iubesc soarele și solul bine drenat.',
    care: 'Evită băltirea, tăieri ușoare pentru înflorire.',
    uses: 'Ornamentale.',
    image: '$_imgDir/caryophyllaceae.jpg',
  ),
  'Apiaceae': FamilyExtra(
    desc: 'Umbelifere: morcov, pătrunjel, țelină.',
    care: 'Sol bogat, udare constantă; atenție la tulpinile florale.',
    uses: 'Alimentare, condimente, medicinale.',
    image: '$_imgDir/apiaceae.jpg',
  ),
  'Asparagaceae': FamilyExtra(
    desc: 'Sparanghel, agave, yucca, dracaena.',
    care: 'Specii variate; majoritatea cer lumină bună și drenaj.',
    uses: 'Alimentare (sparanghel), ornamentale.',
    image: '$_imgDir/asparagaceae.jpg',
  ),
  'Asteraceae': FamilyExtra(
    desc: 'Cea mai mare familie: floarea-soarelui, salată, gălbenele.',
    care: 'Soare, udare moderată, îndepărtarea florilor trecute.',
    uses: 'Alimentare, uleiuri, ornamentale, medicinale.',
    image: '$_imgDir/asteraceae.jpg',
  ),
  'Brassicaceae': FamilyExtra(
    desc: 'Varză, rapiță, muștar — preferă răcoare.',
    care: 'Sol fertil, udare regulată; protecție contra dăunătorilor.',
    uses: 'Alimentare, uleiuri, condimente.',
    image: '$_imgDir/brassicaceae.jpg',
  ),
  'Chenopodiaceae': FamilyExtra(
    desc: 'Spanac, sfeclă — azi încadrate adesea în Amaranthaceae.',
    care: 'Sol bogat, udare constantă.',
    uses: 'Alimentare, furaje, industrial (zahăr).',
    image: '$_imgDir/chenopodiaceae.jpg',
  ),
  'Cypressaceae': FamilyExtra(
    desc: 'Conifere.',
    care: 'Soare, drenaj bun; suportă seceta după prindere.',
    uses: 'Ornamentale, lemn, gard viu.',
    image: '$_imgDir/cupressaceae.jpg',
  ),
  'Cupressaceae': FamilyExtra(
    desc: 'Chiparoși, tuia, ienupăr.',
    care: 'Soare, drenaj; tăieri de formă moderate.',
    uses: 'Ornamentale, gard viu, lemn.',
    image: '$_imgDir/cupressaceae.jpg',
  ),
  'Erythroxylaceae': FamilyExtra(
    desc: 'Puține specii; în general tropicale.',
    care: 'Căldură, lumină, drenaj.',
    uses: 'Cercetare, ornamentale.',
    image: '$_imgDir/erythroxylaceae.jpg',
  ),
  'Fabaceae': FamilyExtra(
    desc: 'Leguminoase: fasole, mazăre, trifoi. Fixează azot.',
    care: 'Sol aerat, udare moderată, suport/sfori pt. cățărătoare.',
    uses: 'Alimentare, furaje, îmbogățirea solului.',
    image: '$_imgDir/fabaceae.png',
  ),
  'Cucurbitaceae': FamilyExtra(
    desc: 'Castraveți, dovleci, pepeni — liane viguroase.',
    care: 'Multă apă pe căldură; spațiu; polenizare.',
    uses: 'Alimentare, semințe comestibile.',
    image: '$_imgDir/cucurbitaceae.jpg',
  ),
  'Fagaceae': FamilyExtra(
    desc: 'Stejar, fag, castan.',
    care: 'Sol adânc, drenaj; suportă bine frigul.',
    uses: 'Lemn, fructe (castan).',
    image: '$_imgDir/fagaceae.jpg',
  ),
  'Fouquieriaceae': FamilyExtra(
    desc: 'Arbuști suculenți (ocotillo) din zone aride.',
    care: 'Mult soare, foarte puțină apă; drenaj excelent.',
    uses: 'Ornamental xerofit.',
    image: '$_imgDir/fouquieriaceae.jpg',
  ),
  'Heatheraceae': FamilyExtra(
    desc: 'Erica/Calluna (Ericaceae).',
    care: 'Sol acid, udare regulată; soare parțial.',
    uses: 'Ornamentale, melifere.',
    image: '$_imgDir/heatheraceae.jpg',
  ),
  'Lamiaceae': FamilyExtra(
    desc: 'Mente, busuioc, lavandă; tulpini pătrate, frunze aromate.',
    care: 'Soare, drenaj; tăieri ușoare.',
    uses: 'Condimente, uleiuri esențiale, ornamentale.',
    image: '$_imgDir/lamiaceae.png',
  ),
  'Malvaceae': FamilyExtra(
    desc: 'Tei, hibiscus, bumbac.',
    care: 'Soare, fertilizare moderată; protecție contra afidelor.',
    uses: 'Ornamentale, textile, apicole.',
    image: '$_imgDir/malvaceae.jpg',
  ),
  'Myrtaceae': FamilyExtra(
    desc: 'Eucalipt, mirt, guava.',
    care: 'Soare, drenaj; unele iubesc căldura.',
    uses: 'Ornamentale, uleiuri, fructe.',
    image: '$_imgDir/myrtaceae.jpg',
  ),
};

String _matchKeyCI(Map<String, dynamic> map, String key) {
  final k = key.trim().toLowerCase();
  return map.keys.firstWhere(
    (e) => e.toLowerCase() == k,
    orElse: () => key,
  );
}

class PlantsPage extends StatelessWidget {
  const PlantsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.latest;
    final familyRaw = t?.family ?? '';
    final familyKey = familyRaw.isEmpty ? '' : _matchKeyCI(kFamilyInfo, familyRaw);
    final info = familyKey.isEmpty ? null : kFamilyInfo[familyKey];
    final optSoil = t?.familyOptimalSoil ?? -1;

    return Scaffold(
      appBar: AppBar(title: const Text('Familia plantei')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (info != null)
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.asset(
                      info.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported_outlined, size: 48),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 140,
                    color: Colors.grey.shade100,
                    alignment: Alignment.center,
                    child: const Icon(Icons.eco_outlined, size: 48),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.eco_outlined),
                      const SizedBox(width: 8),
                      Text(
                        familyKey.isEmpty ? '—' : familyKey,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
                if (optSoil >= 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        const Icon(Icons.water_drop, size: 18),
                        const SizedBox(width: 6),
                        Text('Umiditate optima sol: ~${optSoil.toStringAsFixed(0)}%'),
                      ],
                    ),
                  ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Descriere', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text(info?.desc ?? 'Apasa butonul pentru a obtine familia plantei.'),
                      const SizedBox(height: 12),
                      Text('Ingrijire', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text(info?.care ?? '—'),
                      const SizedBox(height: 12),
                      Text('Folosiri', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text(info?.uses ?? '—'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              try {
                await context.read<AppState>().refreshPredictions(); 
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Predictie actualizata')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Eroare: $e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Obtine predictia familiei'),
          ),
        ],
      ),
    );
  }
}
