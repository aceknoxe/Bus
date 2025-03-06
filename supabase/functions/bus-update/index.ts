import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

interface BusUpdate {
  bus_id: string
  stop_id: string
  timestamp: string
}

serve(async (req) => {
  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { bus_id, stop_id } = await req.json() as BusUpdate

    // Validate bus_id and stop_id exist
    const [busResult, stopResult] = await Promise.all([
      supabaseClient.from('buses').select('id').eq('id', bus_id).single(),
      supabaseClient.from('bus_stops').select('id').eq('id', stop_id).single()
    ])

    if (!busResult.data || !stopResult.data) {
      return new Response(
        JSON.stringify({ error: 'Invalid bus_id or stop_id' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Update bus location
    const { error } = await supabaseClient.from('buses').update({
      current_stop_id: stop_id,
      last_update: new Date().toISOString()
    }).eq('id', bus_id)

    if (error) throw error

    // Emit real-time event
    await supabaseClient.from('bus_updates').insert({
      bus_id,
      stop_id,
      timestamp: new Date().toISOString()
    })

    return new Response(
      JSON.stringify({ success: true }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})