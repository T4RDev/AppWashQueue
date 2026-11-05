import { Request } from 'express';

export type UserRole = 'member' | 'owner' | 'admin';
export type UserStatus = 'active' | 'suspended';
export type VehicleType = 'motorcycle' | 'car' | 'suv';
export type ShopStatus = 'pending' | 'approved' | 'rejected' | 'suspended';
export type DayOfWeek = 'monday' | 'tuesday' | 'wednesday' | 'thursday' | 'friday' | 'saturday' | 'sunday';
export type BookingStatus =
  | 'pending_service'
  | 'checked_in'
  | 'in_service'
  | 'completed'
  | 'no_show'
  | 'cancelled_by_user'
  | 'cancelled_by_shop';
export type PaymentStatus = 'paid' | 'refunded' | 'released_to_shop';
export type TransactionType = 'topup' | 'booking_payment' | 'booking_earning' | 'refund' | 'withdrawal';
export type TransactionStatus = 'pending' | 'completed' | 'rejected';
export type WithdrawalStatus = 'pending' | 'approved' | 'rejected';
export type NotificationType =
  | 'booking_confirmed'
  | 'reminder_30m'
  | 'service_completed'
  | 'booking_cancelled'
  | 'wallet_update'
  | 'system';

export interface UserPayload {
  id: number;
  email: string;
  role: UserRole;
  full_name: string;
}

export interface AuthRequest extends Request {
  user?: UserPayload;
}
