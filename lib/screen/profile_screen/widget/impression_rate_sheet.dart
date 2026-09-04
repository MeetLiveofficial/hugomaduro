import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/manager/guest_gate.dart';
import 'package:krimson/common/service/api/user_service.dart';
import 'package:krimson/common/widget/loader_widget.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';

/// Encuesta de impresión: el cliente marca cualidades (Foodie, Traveler…).
/// Alimenta las barras y el rating del perfil de la streamer.
class ImpressionRateSheet extends StatefulWidget {
  const ImpressionRateSheet({
    super.key,
    required this.streamerId,
    this.onSaved,
    this.title,
  });

  final int streamerId;
  final ValueChanged<User?>? onSaved;
  final String? title;

  static const _sheet = Color(0xFF0B0B0F);
  static const maxChecks = 6;

  static Future<void> show({
    required int streamerId,
    ValueChanged<User?>? onSaved,
    String? title,
  }) async {
    if (GuestGate.isAnonymous) return;
    await Get.bottomSheet(
      ImpressionRateSheet(
        streamerId: streamerId,
        onSaved: onSaved,
        title: title,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  State<ImpressionRateSheet> createState() => _ImpressionRateSheetState();
}

class _ImpressionRateSheetState extends State<ImpressionRateSheet> {
  final _query = TextEditingController();
  List<ImpressionQuality> _traits = const [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final traits = await UserService.instance.fetchImpressionCatalog(
      streamerId: widget.streamerId,
    );
    if (!mounted) return;
    setState(() {
      _traits = traits;
      _loading = false;
    });
  }

  int get _checkedCount => _traits.where((t) => t.checked).length;

  List<ImpressionQuality> get _visible {
    final q = _query.text.trim().toLowerCase();
    if (q.isEmpty) return _traits;
    return _traits.where((t) => t.label.toLowerCase().contains(q)).toList();
  }

  void _toggle(ImpressionQuality trait) {
    final id = trait.id;
    if (id == null) return;
    if (!trait.checked && _checkedCount >= ImpressionRateSheet.maxChecks) {
      BaseController.share.showSnackBar(
        LKey.maxTraitsHint.trParams({'count': '${ImpressionRateSheet.maxChecks}'}),
      );
      return;
    }
    setState(() {
      _traits = [
        for (final item in _traits)
          if (item.id == id) item.copyWith(checked: !item.checked) else item,
      ];
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final ids = _traits
        .where((t) => t.checked && t.id != null)
        .map((t) => t.id!)
        .toList();
    final updated = await UserService.instance.rateImpression(
      streamerId: widget.streamerId,
      traitIds: ids,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (updated == null) return;
    Get.back();
    widget.onSaved?.call(updated);
    BaseController.share.showSnackBar(LKey.ratingSaved.tr, translate: false);
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    final picks = visible.where((t) => t.isPick).toList();
    final others = visible.where((t) => !t.isPick).toList();
    final title = widget.title ?? LKey.rateImpression.tr;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Container(
          height: MediaQuery.sizeOf(context).height * 0.82,
          decoration: const BoxDecoration(
            color: ImpressionRateSheet._sheet,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyleCustom.outFitMedium500(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      LKey.maxTraitsHint.trParams(
                          {'count': '${ImpressionRateSheet.maxChecks}'}),
                      style: TextStyleCustom.outFitRegular400(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    IconButton(
                      onPressed: Get.back,
                      icon: const Icon(Icons.close, color: Colors.white54),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _query,
                  onChanged: (_) => setState(() {}),
                  style: TextStyleCustom.outFitRegular400(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: LKey.searchHere.tr,
                    hintStyle: TextStyleCustom.outFitRegular400(
                      color: Colors.white38,
                      fontSize: 14,
                    ),
                    prefixIcon:
                        const Icon(Icons.search, color: Colors.white38, size: 20),
                    filled: true,
                    fillColor: const Color(0xFF1A1A1F),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _loading
                    ? const LoaderWidget(color: ColorRes.mlPurple)
                    : visible.isEmpty
                        ? Center(
                            child: Text(
                              LKey.callEmptyTitle.tr,
                              style: TextStyleCustom.outFitRegular400(
                                color: Colors.white54,
                                fontSize: 14,
                              ),
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                            children: [
                              if (picks.isNotEmpty) ...[
                                _TraitSectionTitle(
                                  title: LKey.herTraits.tr,
                                  color: const Color(0xFFC4B5FD),
                                ),
                                for (final trait in picks)
                                  _TraitCheckRow(
                                    trait: trait,
                                    highlight: true,
                                    onTap: () => _toggle(trait),
                                  ),
                                const SizedBox(height: 8),
                              ],
                              if (others.isNotEmpty) ...[
                                _TraitSectionTitle(
                                  title: LKey.otherTraits.tr,
                                  color: Colors.white70,
                                ),
                                for (final trait in others)
                                  _TraitCheckRow(
                                    trait: trait,
                                    highlight: false,
                                    onTap: () => _toggle(trait),
                                  ),
                              ],
                            ],
                          ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _saving || _loading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorRes.mlPurple,
                      disabledBackgroundColor: Colors.white12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            '${LKey.saveRating.tr}  ($_checkedCount/${ImpressionRateSheet.maxChecks})',
                            style: TextStyleCustom.outFitMedium500(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TraitSectionTitle extends StatelessWidget {
  final String title;
  final Color color;

  const _TraitSectionTitle({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Text(
        title,
        style: TextStyleCustom.outFitMedium500(color: color, fontSize: 13),
      ),
    );
  }
}

class _TraitCheckRow extends StatelessWidget {
  final ImpressionQuality trait;
  final bool highlight;
  final VoidCallback onTap;

  const _TraitCheckRow({
    required this.trait,
    required this.highlight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                trait.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyleCustom.outFitMedium500(
                  color: highlight ? const Color(0xFFC4B5FD) : Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
            if (trait.votes > 0)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  '${trait.votes}',
                  style: TextStyleCustom.outFitRegular400(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ),
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: trait.checked,
                onChanged: (_) => onTap(),
                activeColor: ColorRes.mlPurple,
                checkColor: Colors.white,
                side: const BorderSide(color: Colors.white38),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
