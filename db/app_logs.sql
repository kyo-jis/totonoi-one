-- =====================================================
-- app_logs テーブル — ユーザーアクティビティログ
-- Supabase SQL Editor で実行してください
-- =====================================================

-- 1. テーブル作成
CREATE TABLE IF NOT EXISTS public.app_logs (
  id         uuid        DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id    uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  app        text        NOT NULL,
  action     text        NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_app_logs_user_app   ON public.app_logs(user_id, app);
CREATE INDEX IF NOT EXISTS idx_app_logs_created_at ON public.app_logs(created_at);

-- 2. RLS (ログイン済みユーザーは自分のログを INSERT のみ可)
ALTER TABLE public.app_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "logs_insert_own" ON public.app_logs;
CREATE POLICY "logs_insert_own"
  ON public.app_logs FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- 3. 管理者専用統計 RPC（SECURITY DEFINER で全行読み取り）
CREATE OR REPLACE FUNCTION public.get_admin_stats()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_email  text;
  v_result json;
BEGIN
  SELECT email INTO v_email FROM auth.users WHERE id = auth.uid();

  IF v_email NOT IN ('kyouji.o.2@gmail.com', 'kyouji.o@gmail.com') THEN
    RAISE EXCEPTION 'Unauthorized: admin only';
  END IF;

  SELECT json_build_object(
    'total_users', (
      SELECT COUNT(*) FROM auth.users
    ),
    'today_active', (
      SELECT COUNT(DISTINCT user_id) FROM public.app_logs
      WHERE created_at >= CURRENT_DATE
    ),
    'week_active', (
      SELECT COUNT(DISTINCT user_id) FROM public.app_logs
      WHERE created_at >= CURRENT_DATE - INTERVAL '6 days'
    ),
    'month_active', (
      SELECT COUNT(DISTINCT user_id) FROM public.app_logs
      WHERE created_at >= CURRENT_DATE - INTERVAL '29 days'
    ),
    'pro_count', (
      SELECT COUNT(*) FROM public.profiles WHERE is_pro = true
    ),
    'free_count', (
      SELECT COUNT(*) FROM auth.users
    ) - (
      SELECT COUNT(*) FROM public.profiles WHERE is_pro = true
    ),
    'app_ranking', (
      SELECT COALESCE(json_agg(row_to_json(t)), '[]'::json)
      FROM (
        SELECT
          app,
          COUNT(DISTINCT user_id) AS users,
          COUNT(*) AS opens
        FROM public.app_logs
        WHERE action = 'open'
        GROUP BY app
        ORDER BY users DESC
      ) t
    )
  ) INTO v_result;

  RETURN v_result;
END;
$$;
