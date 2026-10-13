(async ()=>{
  const {PrismaClient} = await import('@prisma/client');
  const p = new PrismaClient();
  const m = p._dmmf.schema.models.find(m => m.name === 'User');
  console.log(JSON.stringify(m, null, 2));
  await p.$disconnect();
})();
