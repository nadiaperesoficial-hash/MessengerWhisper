import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

Deno.serve(async (req) => {
  try {
    // O próprio Supabase (Instância A) já valida o JWT antes de chamar essa função
    // (fica configurado assim no deploy). Aqui só extraímos o usuário autenticado.
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Não autenticado' }), { status: 401 });
    }

    const supabaseA = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } },
    );

    const { data: userData, error: userError } = await supabaseA.auth.getUser();
    if (userError || !userData.user) {
      return new Response(JSON.stringify({ error: 'Usuário inválido' }), { status: 401 });
    }
    const userId = userData.user.id;

    const { base64Data, fileExt, folder } = await req.json();
    if (!base64Data || !fileExt) {
      return new Response(JSON.stringify({ error: 'Dados incompletos' }), { status: 400 });
    }

    const bytes = Uint8Array.from(atob(base64Data), (c) => c.charCodeAt(0));
    const path = `${userId}/${folder ?? 'misc'}/${Date.now()}.${fileExt}`;

    // Aqui sim usamos a service_role da Instância B — só existe dentro do servidor.
    const supabaseB = createClient(
      Deno.env.get('SUPABASE_B_URL')!,
      Deno.env.get('SUPABASE_B_SERVICE_ROLE_KEY')!,
    );

    const { error: uploadError } = await supabaseB.storage
      .from('media')
      .upload(path, bytes, { contentType: `image/${fileExt}`, upsert: false });

    if (uploadError) {
      return new Response(JSON.stringify({ error: uploadError.message }), { status: 500 });
    }

    const { data: publicUrlData } = supabaseB.storage.from('media').getPublicUrl(path);

    return new Response(JSON.stringify({ url: publicUrlData.publicUrl }), {
      headers: { 'Content-Type': 'application/json' },
      status: 200,
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }
});
