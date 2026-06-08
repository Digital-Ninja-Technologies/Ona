import React, { useState, useEffect } from "react";
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
  TextInput,
  Alert,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { StatusBar } from "expo-status-bar";
import { router, useLocalSearchParams } from "expo-router";
import {
  ArrowLeft,
  Calendar,
  Users,
  CreditCard,
  Check,
} from "lucide-react-native";
import {
  useFonts,
  Nunito_400Regular,
  Nunito_500Medium,
  Nunito_600SemiBold,
  Nunito_700Bold,
} from "@expo-google-fonts/nunito";
import { Fredoka_500Medium } from "@expo-google-fonts/fredoka";
import { useTheme } from "@/utils/theme/useTheme";
import { useAuth } from "@/utils/auth/useAuth";
import useUser from "@/utils/auth/useUser";

export default function BookingFlowScreen() {
  const insets = useSafeAreaInsets();
  const { theme } = useTheme();
  const { isAuthenticated, signIn } = useAuth();
  const { user } = useUser();
  const { experienceId, price } = useLocalSearchParams();
  const [selectedDate, setSelectedDate] = useState(null);
  const [participants, setParticipants] = useState(1);
  const [loading, setLoading] = useState(false);
  const [experience, setExperience] = useState(null);

  const [fontsLoaded] = useFonts({
    Nunito_400Regular,
    Nunito_500Medium,
    Nunito_600SemiBold,
    Nunito_700Bold,
    Fredoka_500Medium,
  });

  useEffect(() => {
    if (experienceId) {
      fetchExperience();
    }
    // Set default date to tomorrow
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    setSelectedDate(tomorrow.toISOString().split("T")[0]);
  }, [experienceId]);

  const fetchExperience = async () => {
    try {
      const response = await fetch(`/api/experiences/${experienceId}`);
      if (response.ok) {
        const data = await response.json();
        setExperience(data);
      }
    } catch (error) {
      console.error("Error fetching experience:", error);
    }
  };

  const totalPrice = (parseFloat(price || 0) * participants).toFixed(2);
  const commission = (parseFloat(totalPrice) * 0.15).toFixed(2);

  const handleConfirmBooking = async () => {
    if (!isAuthenticated || !user) {
      Alert.alert("Sign In Required", "Please sign in to book experiences.", [
        { text: "Cancel", style: "cancel" },
        { text: "Sign In", onPress: () => signIn() },
      ]);
      return;
    }

    try {
      setLoading(true);
      const response = await fetch("/api/bookings", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          userId: user.id,
          experienceId: parseInt(experienceId),
          bookingDate: selectedDate,
          numParticipants: participants,
          totalPrice: parseFloat(totalPrice),
          commissionAmount: parseFloat(commission),
        }),
      });

      if (!response.ok) {
        throw new Error("Failed to create booking");
      }

      const data = await response.json();
      router.push(`/booking-success?bookingId=${data.booking.id}`);
    } catch (error) {
      console.error("Error creating booking:", error);
      Alert.alert(
        "Booking Failed",
        "Could not complete your booking. Please try again.",
      );
    } finally {
      setLoading(false);
    }
  };

  if (!fontsLoaded) {
    return null;
  }

  const handleBackPress = () => {
    router.back();
  };

  return (
    <View style={styles.container}>
      <StatusBar style={theme.statusBarStyle} />

      {/* Header */}
      <View style={[styles.header, { paddingTop: insets.top + 16 }]}>
        <TouchableOpacity style={styles.backButton} onPress={handleBackPress}>
          <ArrowLeft size={24} color={theme.icon} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Complete Booking</Text>
      </View>

      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={[
          styles.contentContainer,
          { paddingBottom: insets.bottom + 120 },
        ]}
        showsVerticalScrollIndicator={false}
      >
        {/* Experience Title */}
        {experience && (
          <View style={styles.experienceInfo}>
            <Text style={styles.experienceTitle}>{experience.title}</Text>
            <Text style={styles.experienceCategory}>{experience.category}</Text>
          </View>
        )}

        {/* Date Selection */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Calendar size={20} color="#FF6B9D" />
            <Text style={styles.sectionTitle}>Select Date</Text>
          </View>

          <TextInput
            style={styles.input}
            value={selectedDate}
            onChangeText={setSelectedDate}
            placeholder="YYYY-MM-DD"
            placeholderTextColor="#999"
          />
        </View>

        {/* Participants */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Users size={20} color="#FF6B9D" />
            <Text style={styles.sectionTitle}>Number of Participants</Text>
          </View>

          <View style={styles.participantsControl}>
            <TouchableOpacity
              style={[
                styles.participantButton,
                participants <= 1 && styles.participantButtonDisabled,
              ]}
              onPress={() => setParticipants(Math.max(1, participants - 1))}
              disabled={participants <= 1}
            >
              <Text style={styles.participantButtonText}>-</Text>
            </TouchableOpacity>

            <Text style={styles.participantsCount}>{participants}</Text>

            <TouchableOpacity
              style={styles.participantButton}
              onPress={() =>
                setParticipants(
                  Math.min(
                    experience?.max_participants || 10,
                    participants + 1,
                  ),
                )
              }
            >
              <Text style={styles.participantButtonText}>+</Text>
            </TouchableOpacity>
          </View>
        </View>

        {/* Price Breakdown */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <CreditCard size={20} color="#FF6B9D" />
            <Text style={styles.sectionTitle}>Price Breakdown</Text>
          </View>

          <View style={styles.priceBreakdown}>
            <View style={styles.priceRow}>
              <Text style={styles.priceLabel}>
                ${price} × {participants} participant
                {participants > 1 ? "s" : ""}
              </Text>
              <Text style={styles.priceValue}>${totalPrice}</Text>
            </View>

            <View style={styles.priceRow}>
              <Text style={styles.priceLabel}>Service fee (15%)</Text>
              <Text style={styles.priceValue}>${commission}</Text>
            </View>

            <View style={styles.divider} />

            <View style={styles.priceRow}>
              <Text style={styles.totalLabel}>Total</Text>
              <Text style={styles.totalValue}>${totalPrice}</Text>
            </View>
          </View>
        </View>

        {/* Terms */}
        <View style={styles.termsSection}>
          <Text style={styles.termsText}>
            By confirming this booking, you agree to our Terms of Service and
            Cancellation Policy. You can cancel free of charge up to 24 hours
            before the experience.
          </Text>
        </View>
      </ScrollView>

      {/* Confirm Footer */}
      <View
        style={[styles.confirmFooter, { paddingBottom: insets.bottom + 16 }]}
      >
        <View style={styles.totalContainer}>
          <Text style={styles.totalFooterLabel}>Total</Text>
          <Text style={styles.totalFooterValue}>${totalPrice}</Text>
        </View>

        <TouchableOpacity
          style={[
            styles.confirmButton,
            loading && styles.confirmButtonDisabled,
          ]}
          onPress={handleConfirmBooking}
          disabled={loading}
          activeOpacity={0.9}
        >
          <Text style={styles.confirmButtonText}>
            {loading ? "Processing..." : "Confirm Booking"}
          </Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#FFFFFF",
  },
  header: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: 20,
    paddingBottom: 16,
    borderBottomWidth: 1,
    borderBottomColor: "#F0F0F0",
  },
  backButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: "#F5F5F5",
    justifyContent: "center",
    alignItems: "center",
    marginRight: 12,
  },
  headerTitle: {
    fontFamily: "Fredoka_500Medium",
    fontSize: 20,
    color: "#000",
  },
  scrollView: {
    flex: 1,
  },
  contentContainer: {
    paddingHorizontal: 24,
    paddingTop: 24,
  },
  experienceInfo: {
    marginBottom: 24,
  },
  experienceTitle: {
    fontFamily: "Nunito_700Bold",
    fontSize: 22,
    color: "#000",
    marginBottom: 4,
  },
  experienceCategory: {
    fontFamily: "Nunito_500Medium",
    fontSize: 14,
    color: "#666",
  },
  section: {
    marginBottom: 24,
  },
  sectionHeader: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
    marginBottom: 12,
  },
  sectionTitle: {
    fontFamily: "Nunito_600SemiBold",
    fontSize: 16,
    color: "#000",
  },
  input: {
    backgroundColor: "#F9FAFB",
    borderRadius: 12,
    paddingHorizontal: 16,
    paddingVertical: 14,
    fontFamily: "Nunito_500Medium",
    fontSize: 15,
    color: "#000",
    borderWidth: 1,
    borderColor: "#E5E7EB",
  },
  participantsControl: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    gap: 24,
  },
  participantButton: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: "#FF6B9D",
    justifyContent: "center",
    alignItems: "center",
  },
  participantButtonDisabled: {
    backgroundColor: "#E5E7EB",
  },
  participantButtonText: {
    fontFamily: "Nunito_700Bold",
    fontSize: 24,
    color: "#FFFFFF",
  },
  participantsCount: {
    fontFamily: "Nunito_700Bold",
    fontSize: 32,
    color: "#000",
    minWidth: 60,
    textAlign: "center",
  },
  priceBreakdown: {
    backgroundColor: "#F9FAFB",
    borderRadius: 12,
    padding: 16,
  },
  priceRow: {
    flexDirection: "row",
    justifyContent: "space-between",
    marginBottom: 12,
  },
  priceLabel: {
    fontFamily: "Nunito_400Regular",
    fontSize: 14,
    color: "#666",
  },
  priceValue: {
    fontFamily: "Nunito_600SemiBold",
    fontSize: 14,
    color: "#000",
  },
  divider: {
    height: 1,
    backgroundColor: "#E5E7EB",
    marginVertical: 8,
  },
  totalLabel: {
    fontFamily: "Nunito_700Bold",
    fontSize: 16,
    color: "#000",
  },
  totalValue: {
    fontFamily: "Nunito_700Bold",
    fontSize: 18,
    color: "#FF6B9D",
  },
  termsSection: {
    marginTop: 8,
  },
  termsText: {
    fontFamily: "Nunito_400Regular",
    fontSize: 12,
    color: "#999",
    lineHeight: 18,
  },
  confirmFooter: {
    paddingHorizontal: 24,
    paddingTop: 16,
    borderTopWidth: 1,
    borderTopColor: "#F0F0F0",
    backgroundColor: "#FFFFFF",
  },
  totalContainer: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: 16,
  },
  totalFooterLabel: {
    fontFamily: "Nunito_600SemiBold",
    fontSize: 16,
    color: "#666",
  },
  totalFooterValue: {
    fontFamily: "Nunito_700Bold",
    fontSize: 28,
    color: "#FF6B9D",
  },
  confirmButton: {
    backgroundColor: "#FF6B9D",
    borderRadius: 24,
    paddingVertical: 16,
    alignItems: "center",
  },
  confirmButtonDisabled: {
    backgroundColor: "#E5E7EB",
  },
  confirmButtonText: {
    fontFamily: "Nunito_700Bold",
    fontSize: 16,
    color: "#FFFFFF",
  },
});
