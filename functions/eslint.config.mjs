import { defineConfig } from 'eslint/config';
import tseslint from 'typescript-eslint';

export default defineConfig(
  { ignores: ['lib/**', 'node_modules/**'] },
  tseslint.configs.strictTypeChecked,
  // Plain Node scripts are not part of the TypeScript program, so the
  // type-aware rules have no types to work from. They are still linted for
  // everything that does not need them (ENG-16).
  {
    files: ['tools/**/*.mjs'],
    extends: [tseslint.configs.disableTypeChecked],
    languageOptions: { parserOptions: { projectService: false } },
    rules: { '@typescript-eslint/explicit-function-return-type': 'off' },
  },
  {
    files: ['src/**/*.ts', 'test/**/*.ts', '*.ts', '*.mjs'],
    ignores: ['tools/**'],
    languageOptions: {
      parserOptions: {
        projectService: { allowDefaultProject: ['eslint.config.mjs'] },
        tsconfigRootDir: import.meta.dirname,
      },
    },
    rules: {
      '@typescript-eslint/no-explicit-any': 'error',
      '@typescript-eslint/explicit-function-return-type': 'error',
    },
  },
  // The cloud has no default admin app: firebase-functions registers its own
  // under a name, so a bare getAuth() or getFirestore() throws app/no-app live
  // while the emulator, which always has a default app, passes.
  {
    files: ['src/**/*.ts'],
    ignores: ['src/shared/auth.ts', 'src/shared/firestore.ts'],
    rules: {
      '@typescript-eslint/no-restricted-imports': [
        'error',
        {
          paths: [
            {
              name: 'firebase-admin/auth',
              importNames: ['getAuth'],
              message: 'Use auth() from shared/auth.',
              allowTypeImports: true,
            },
            {
              name: 'firebase-admin/firestore',
              importNames: ['getFirestore'],
              message: 'Use db() from shared/firestore.',
              allowTypeImports: true,
            },
          ],
        },
      ],
    },
  },
);
