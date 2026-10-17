/// Flags de capacidades do produto equivalentes a `lib/feature-flags.ts`.
///
/// Todas as capacidades ficam disponíveis no build final, mantendo o contrato
/// sem esconder rotas ou ferramentas do usuário.
enum FeatureFlag {
  media('NEXT_PUBLIC_FF_MEDIA'),
  semantic('NEXT_PUBLIC_FF_SEMANTIC'),
  anki('NEXT_PUBLIC_FF_ANKI'),
  ankiIo('NEXT_PUBLIC_FF_ANKI_IO'),
  aiIngest('NEXT_PUBLIC_FF_AI_INGEST'),
  gamification('NEXT_PUBLIC_FF_GAMIFICATION'),
  collab('NEXT_PUBLIC_FF_COLLAB'),
  fsrsOpt('NEXT_PUBLIC_FF_FSRS_OPT'),
  exams('NEXT_PUBLIC_FF_EXAMS'),
  occlusion('NEXT_PUBLIC_FF_OCCLUSION'),
  syncWorker('NEXT_PUBLIC_FF_SYNC_WORKER'),
  tags('NEXT_PUBLIC_FF_TAGS'),
  socratic('NEXT_PUBLIC_FF_SOCRATIC'),
  templates('NEXT_PUBLIC_FF_TEMPLATES'),
  references('NEXT_PUBLIC_FF_REFERENCES');

  const FeatureFlag(this.envKey);
  final String envKey;
}

bool isFeatureEnabled(FeatureFlag flag) => true;

Map<FeatureFlag, bool> getFeatureFlags() {
  return {
    for (final flag in FeatureFlag.values) flag: true,
  };
}
