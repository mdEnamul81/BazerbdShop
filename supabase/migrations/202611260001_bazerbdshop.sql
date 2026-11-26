-- BazerbdShop: safe order placement and automatic customer profiles
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, username, role)
  values (
    new.id,
    nullif(new.raw_user_meta_data->>'full_name',''),
    nullif(new.raw_user_meta_data->>'username',''),
    'customer'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

create or replace function public.place_order(p_items jsonb)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_order uuid;
  v_item jsonb;
  v_product public.products%rowtype;
  v_qty integer;
  v_total numeric(12,2) := 0;
begin
  if v_user is null then
    raise exception 'Please sign in before placing an order';
  end if;
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'Your cart is empty';
  end if;

  for v_item in select * from jsonb_array_elements(p_items) loop
    v_qty := (v_item->>'quantity')::integer;
    if v_qty is null or v_qty < 1 or v_qty > 100 then
      raise exception 'Invalid quantity';
    end if;
    select * into v_product
      from public.products
      where id = (v_item->>'product_id')::uuid and is_active = true
      for share;
    if not found then
      raise exception 'A product is no longer available';
    end if;
    v_total := v_total + (v_product.price * v_qty);
  end loop;

  insert into public.orders (user_id, total, status)
  values (v_user, v_total, 'pending')
  returning id into v_order;

  for v_item in select * from jsonb_array_elements(p_items) loop
    v_qty := (v_item->>'quantity')::integer;
    select * into v_product
      from public.products
      where id = (v_item->>'product_id')::uuid and is_active = true
      for share;
    insert into public.order_items (order_id, product_id, product_name, quantity, unit_price)
    values (v_order, v_product.id, v_product.name, v_qty, v_product.price);
  end loop;

  return v_order;
end;
$$;

revoke all on function public.place_order(jsonb) from public;
grant execute on function public.place_order(jsonb) to authenticated;
