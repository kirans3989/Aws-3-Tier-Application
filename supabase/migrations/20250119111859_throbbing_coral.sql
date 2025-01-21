/*
  # Create items table for demo

  1. New Tables
    - `items`
      - `id` (uuid, primary key)
      - `name` (text, not null)
      - `created_at` (timestamp)

  2. Security
    - Enable RLS on `items` table
    - Add policies for CRUD operations
*/

CREATE TABLE IF NOT EXISTS items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow anonymous read access"
  ON items
  FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "Allow anonymous insert access"
  ON items
  FOR INSERT
  TO anon
  WITH CHECK (true);