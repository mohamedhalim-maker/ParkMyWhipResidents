-- Park My Whip Resident App - Row Level Security Policies

-- Enable Row Level Security on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE parking_spots ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE guest_passes ENABLE ROW LEVEL SECURITY;
ALTER TABLE violations ENABLE ROW LEVEL SECURITY;
ALTER TABLE parking_requests ENABLE ROW LEVEL SECURITY;

-- Users table policies
CREATE POLICY users_select_policy ON users
  FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY users_insert_policy ON users
  FOR INSERT
  WITH CHECK (true);

CREATE POLICY users_update_policy ON users
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (true);

CREATE POLICY users_delete_policy ON users
  FOR DELETE
  USING (auth.uid() = id);

-- Parking spots table policies
CREATE POLICY parking_spots_select_policy ON parking_spots
  FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY parking_spots_insert_policy ON parking_spots
  FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY parking_spots_update_policy ON parking_spots
  FOR UPDATE
  USING (auth.uid() = user_id OR auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() = user_id OR auth.uid() IS NOT NULL);

CREATE POLICY parking_spots_delete_policy ON parking_spots
  FOR DELETE
  USING (auth.uid() IS NOT NULL);

-- Vehicles table policies
CREATE POLICY vehicles_select_policy ON vehicles
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY vehicles_insert_policy ON vehicles
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY vehicles_update_policy ON vehicles
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY vehicles_delete_policy ON vehicles
  FOR DELETE
  USING (auth.uid() = user_id);

-- Guest passes table policies
CREATE POLICY guest_passes_select_policy ON guest_passes
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY guest_passes_insert_policy ON guest_passes
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY guest_passes_update_policy ON guest_passes
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY guest_passes_delete_policy ON guest_passes
  FOR DELETE
  USING (auth.uid() = user_id);

-- Violations table policies
CREATE POLICY violations_select_policy ON violations
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY violations_insert_policy ON violations
  FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY violations_update_policy ON violations
  FOR UPDATE
  USING (auth.uid() = user_id OR auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() = user_id OR auth.uid() IS NOT NULL);

CREATE POLICY violations_delete_policy ON violations
  FOR DELETE
  USING (auth.uid() IS NOT NULL);

-- Parking requests table policies
CREATE POLICY parking_requests_select_policy ON parking_requests
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY parking_requests_insert_policy ON parking_requests
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY parking_requests_update_policy ON parking_requests
  FOR UPDATE
  USING (auth.uid() = user_id OR auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() = user_id OR auth.uid() IS NOT NULL);

CREATE POLICY parking_requests_delete_policy ON parking_requests
  FOR DELETE
  USING (auth.uid() = user_id);
