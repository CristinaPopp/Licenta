import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../common/app_state.dart';

//Info pentru specii invazive
class WeedInfo {
  final String desc;
  final String control; //combatere
  final String image;
  const WeedInfo({required this.desc, required this.control, required this.image});
}

const _weedDir = 'assets/weeds';

const Map<String, WeedInfo> kWeeds = {
  'Fromia': WeedInfo(
    desc: 'Nume raportat; verifică eticheta reală din modelul tău.',
    control: 'Îndepărtare manuală; identificare corectă înainte de tratament.',
    image: '$_weedDir/fromia.jpg',
  ),
  'Giant Hogweed': WeedInfo(
    desc: 'Heracleum mantegazzianum — foarte invaziv, sevă fototoxică.',
    control: 'Echipament de protecție! Tăieri repetate; erbicid pe bază de glyphosate – aplicare țintită.',
    image: '$_weedDir/giant_hogweed.jpeg',
  ),
  'Autumn Olive': WeedInfo(
    desc: 'Elaeagnus umbellata – arbust invaziv, semințe răspândite de păsări.',
    control: 'Tăiere + tratarea cioatelor cu triclopyr; smulgere timpurie la exemplare mici.',
    image: '$_weedDir/autumn_olive.jpg',
  ),
  'Burdock': WeedInfo(
    desc: 'Arctium spp.; bi-anual, cu „arici”.',
    control: 'Cosire înainte de înflorire; erbicid selectiv pentru dicotiledonate.',
    image: '$_weedDir/burdock.jpg',
  ),
  'Fireweed': WeedInfo(
    desc: 'Chamerion angustifolium; colonizează rapid zone deschise.',
    control: 'Cosiri repetate; erbicid sistemic dacă e necesar.',
    image: '$_weedDir/fireweed.jpg',
  ),
  'Cypress Vine': WeedInfo(
    desc: 'Ipomoea quamoclit — liană ornamentală devenită invazivă local.',
    control: 'Smulgere înainte de semințe; erbicid pentru vițe anuale.',
    image: '$_weedDir/cypress_vine.jpg',
  ),
  'Common Buckthorn': WeedInfo(
    desc: 'Rhamnus cathartica — arbust invaziv umbrofil.',
    control: 'Smulgere/plivit; tăiere + tratament cu triclopyr pe cioată.',
    image: '$_weedDir/common_buckthorn.jpg',
  ),
  'English Ivy': WeedInfo(
    desc: 'Hedera helix — sufocă arborii și zidurile.',
    control: 'Îndepărtare manuală completă; erbicide doar punctual.',
    image: '$_weedDir/english_ivy.jpg',
  ),
  'Cheatgrass': WeedInfo(
    desc: 'Bromus tectorum — iarbă anuală extrem de invazivă.',
    control: 'Cosire devreme; preemergente (imazapic) în zone aprobate.',
    image: '$_weedDir/cheatgrass.jpg',
  ),
  'Bamboo': WeedInfo(
    desc: 'Diverse specii – rizomi agresivi.',
    control: 'Barieră anti-rizomi; exhaustare prin tăieri repetate; erbicid sistemic.',
    image: '$_weedDir/bamboo.jpg',
  ),
  'Himalayan Blackberry': WeedInfo(
    desc: 'Rubus armeniacus — mărăcini invazivi.',
    control: 'Tăieri repetate; erbicid sistemic (glyphosate/triclopyr) toamna.',
    image: '$_weedDir/himalayan_blackberry.jpg',
  ),
  'Japanese Barberry': WeedInfo(
    desc: 'Berberis thunbergii — produce desișuri dense.',
    control: 'Smulgere; tratament pe cioată; monitorizare semințe.',
    image: '$_weedDir/japanese_barberry.jpg',
  ),
  'Japanese Knotweed': WeedInfo(
    desc: 'Fallopia japonica — rizomi puternici, foarte invaziv.',
    control: 'Program multi-anual; injecție/ungere cu glyphosate; NU fragmentați rizomii.',
    image: '$_weedDir/japanese_knotweed.jpg',
  ),
  'Japanese Stilt Grass': WeedInfo(
    desc: 'Microstegium vimineum — iarbă anuală de umbră.',
    control: 'Cosire înainte de semințe; preemergente (prodiamine).',
    image: '$_weedDir/japanese_stilt_grass.jpg',
  ),
  'Kudzu': WeedInfo(
    desc: 'Pueraria montana — „vița care a înghițit sudul”.',
    control: 'Eradicație pe termen lung; erbicid sistemic + tăieri repetate.',
    image: '$_weedDir/kudzu.jpg',
  ),
  'Lantana': WeedInfo(
    desc: 'Lantana camara — ornament invaziv tropical.',
    control: 'Smulgere; erbicid triclopyr/glyphosate pe cioată.',
    image: '$_weedDir/lantana.jpg',
  ),
  'Miscanthus': WeedInfo(
    desc: 'Iarbă ornamentală; unele specii devin invazive.',
    control: 'Îndepărtare rizomi; erbicid sistemic.',
    image: '$_weedDir/miscanthus.jpg',
  ),
  'Multiflora Rose': WeedInfo(
    desc: 'Rosa multiflora — formează tufe dese.',
    control: 'Tăiere și tratament pe cioată; erbicid sistemic.',
    image: '$_weedDir/multiflora_rose.jpg',
  ),
  'Norway Maple': WeedInfo(
    desc: 'Acer platanoides — arbori dințiți invazivi în unele regiuni.',
    control: 'Îndepărtare exemplare tinere; tratamente pe cioată.',
    image: '$_weedDir/norway_maple.jpg',
  ),
  'Purple Loosestrife': WeedInfo(
    desc: 'Lythrum salicaria — invaziv în zone umede.',
    control: 'Erbicid aprobat pentru zone umede (imazapyr/glyphosate); control biologic local.',
    image: '$_weedDir/purple_loosestrife.jpg',
  ),
};

String _matchWeedKey(String lbl) {
  final k = lbl.trim().toLowerCase();
  return kWeeds.keys.firstWhere(
    (e) => e.toLowerCase() == k,
    orElse: () => lbl,
  );
}

class WeedsPage extends StatelessWidget {
  const WeedsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.latest;
    final invLabelRaw = t?.invasive ?? '';
    final invLabelKey = invLabelRaw.isEmpty ? '' : _matchWeedKey(invLabelRaw);
    final invScore = (t?.invasiveScore ?? 0.0).clamp(0.0, 1.0);
    final info = invLabelKey.isEmpty ? null : kWeeds[invLabelKey];
    final pct = (invScore * 100).toStringAsFixed(0);
    final lowConfidence = invScore < 0.50;

    return Scaffold(
      appBar: AppBar(title: const Text('Buruieni')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (lowConfidence)
            Card(
              color: Colors.amber.shade100,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_outlined),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Este posibil ca predictia sa nu fie corecta (acuratete $pct%). '
                        'Verificati informatiile furnizate!',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                    child: const Icon(Icons.grass_outlined, size: 48),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.grass_outlined),
                      const SizedBox(width: 8),
                      Text(
                        invLabelKey.isEmpty ? '—' : invLabelKey,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: invScore >= 0.8
                              ? Colors.green.withOpacity(.15)
                              : invScore >= 0.5
                                  ? Colors.orange.withOpacity(.15)
                                  : Colors.red.withOpacity(.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text('Acuratete $pct%'),
                      ),
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
                      Text(info?.desc ?? 'Apasa butonul pentru a obtine predictia.'),
                      const SizedBox(height: 12),
                      Text('Combatere / erbicid', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text(info?.control ?? '—'),
                      const SizedBox(height: 8),
                      const Text(
                        '⚠️ Respecta legislatia locala si etichetele produselor. Foloseste echipament de protectie.',
                        style: TextStyle(fontSize: 12),
                      ),
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
                await context.read<AppState>().refreshPredictions(); //POST /predict + refresh /telemetry
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
            label: const Text('Obtine predictia cu privire la eventualele buruieni'),
          ),
        ],
      ),
    );
  }
}
