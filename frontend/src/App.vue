<template>
  <div class="min-h-screen bg-gradient-to-br from-slate-950 via-slate-900 to-emerald-950 text-slate-100">
    <header class="mx-auto max-w-5xl px-6 py-10">
      <div class="inline-flex items-center gap-3 rounded-full border border-emerald-400/30 bg-emerald-400/10 px-4 py-2 text-sm uppercase tracking-[0.2em] text-emerald-200">
        <span class="h-2 w-2 rounded-full bg-emerald-300"></span>
        AFitAccess
      </div>
      <h1 class="mt-6 text-4xl font-semibold leading-tight text-white md:text-6xl">
        Coaching nutrition & fitness sans friction.
      </h1>
      <p class="mt-4 max-w-2xl text-base text-slate-300 md:text-lg">
        L'application qui connecte coachs, patients et plans nutritionnels avec un suivi simple et fluide.
      </p>
    </header>
    <main class="mx-auto max-w-5xl px-6 pb-16">
      <router-view />
    </main>
  </div>
</template>
