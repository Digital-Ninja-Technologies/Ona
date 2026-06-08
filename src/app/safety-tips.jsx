import React, { useState } from "react";
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { StatusBar } from "expo-status-bar";
import { router } from "expo-router";
import {
  ArrowLeft,
  Shield,
  Heart,
  Car,
  Home,
  Briefcase,
  Sun,
} from "lucide-react-native";
import {
  useFonts,
  Nunito_400Regular,
  Nunito_500Medium,
  Nunito_600SemiBold,
} from "@expo-google-fonts/nunito";
import { Fredoka_500Medium } from "@expo-google-fonts/fredoka";
import { useTheme } from "@/utils/theme/useTheme";

const safetyCategories = [
  {
    id: "general",
    title: "General Safety",
    icon: Shield,
    color: "#FF6B9D",
    tips: [
      "Keep copies of important documents in multiple places",
      "Share your itinerary with family or friends",
      "Register with your embassy when traveling abroad",
      "Keep emergency contacts saved in your phone",
      "Stay aware of your surroundings at all times",
      "Avoid displaying expensive jewelry or electronics",
    ],
  },
  {
    id: "health",
    title: "Health & Medical",
    icon: Heart,
    color: "#FF3B30",
    tips: [
      "Get travel insurance with medical coverage",
      "Pack a basic first-aid kit",
      "Research required vaccinations for your destination",
      "Bring enough prescription medications",
      "Drink bottled or purified water in developing countries",
      "Know the location of nearby hospitals and clinics",
    ],
  },
  {
    id: "transportation",
    title: "Transportation",
    icon: Car,
    color: "#34C759",
    tips: [
      "Use licensed taxis or ride-sharing apps",
      "Keep car doors locked and windows up",
      "Don't accept rides from strangers",
      "Sit in the back seat when using taxis",
      "Avoid traveling alone at night",
      "Research safe transportation options before arrival",
    ],
  },
  {
    id: "accommodation",
    title: "Accommodation",
    icon: Home,
    color: "#5856D6",
    tips: [
      "Use hotel safes for valuables and documents",
      "Check door locks and windows upon arrival",
      "Know the emergency exits in your accommodation",
      "Don't share your room number with strangers",
      "Read reviews before booking accommodations",
      "Keep your room key secure at all times",
    ],
  },
  {
    id: "money",
    title: "Money & Valuables",
    icon: Briefcase,
    color: "#FF9500",
    tips: [
      "Use ATMs inside banks or shopping centers",
      "Notify your bank of travel plans",
      "Carry multiple payment methods",
      "Use a money belt or hidden pouch",
      "Don't carry all cash in one place",
      "Be cautious of card skimmers at ATMs",
    ],
  },
  {
    id: "weather",
    title: "Weather & Nature",
    icon: Sun,
    color: "#FFD60A",
    tips: [
      "Check weather forecasts regularly",
      "Pack appropriate clothing for the climate",
      "Stay hydrated in hot weather",
      "Use sunscreen with high SPF",
      "Know what to do in case of natural disasters",
      "Respect local wildlife and keep distance",
    ],
  },
];

export default function SafetyTipsScreen() {
  const insets = useSafeAreaInsets();
  const { theme } = useTheme();
  const [expandedCategory, setExpandedCategory] = useState(null);

  const [fontsLoaded] = useFonts({
    Nunito_400Regular,
    Nunito_500Medium,
    Nunito_600SemiBold,
    Fredoka_500Medium,
  });

  if (!fontsLoaded) return null;

  const toggleCategory = (id) => {
    setExpandedCategory(expandedCategory === id ? null : id);
  };

  const styles = StyleSheet.create({
    container: { flex: 1, backgroundColor: theme.background },
    header: {
      flexDirection: "row",
      alignItems: "center",
      paddingHorizontal: 20,
      paddingBottom: 16,
      borderBottomWidth: 1,
      borderBottomColor: theme.border,
    },
    backButton: {
      width: 40,
      height: 40,
      borderRadius: 20,
      backgroundColor: theme.surface,
      justifyContent: "center",
      alignItems: "center",
      marginRight: 12,
    },
    headerTitle: {
      fontFamily: "Fredoka_500Medium",
      fontSize: 20,
      color: theme.text,
    },
    scrollView: { flex: 1 },
    contentContainer: { paddingHorizontal: 24, paddingTop: 24 },
    subtitle: {
      fontFamily: "Nunito_400Regular",
      fontSize: 15,
      color: theme.textSecondary,
      lineHeight: 22,
      marginBottom: 24,
    },
    categoryCard: {
      backgroundColor: theme.surface,
      borderRadius: 16,
      marginBottom: 12,
      borderWidth: 1,
      borderColor: theme.border,
      overflow: "hidden",
    },
    categoryHeader: {
      flexDirection: "row",
      alignItems: "center",
      padding: 20,
    },
    iconContainer: {
      width: 48,
      height: 48,
      borderRadius: 24,
      justifyContent: "center",
      alignItems: "center",
      marginRight: 16,
    },
    categoryTitle: {
      flex: 1,
      fontFamily: "Nunito_600SemiBold",
      fontSize: 16,
      color: theme.text,
    },
    tipsContainer: {
      paddingHorizontal: 20,
      paddingBottom: 20,
    },
    tipItem: {
      flexDirection: "row",
      marginBottom: 12,
    },
    tipBullet: {
      width: 6,
      height: 6,
      borderRadius: 3,
      backgroundColor: theme.textSecondary,
      marginRight: 12,
      marginTop: 7,
    },
    tipText: {
      flex: 1,
      fontFamily: "Nunito_400Regular",
      fontSize: 14,
      color: theme.text,
      lineHeight: 20,
    },
  });

  return (
    <View style={styles.container}>
      <StatusBar style={theme.statusBarStyle} />

      <View style={[styles.header, { paddingTop: insets.top + 16 }]}>
        <TouchableOpacity
          style={styles.backButton}
          onPress={() => router.back()}
        >
          <ArrowLeft size={24} color={theme.icon} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Safety Tips</Text>
      </View>

      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={[
          styles.contentContainer,
          { paddingBottom: insets.bottom + 20 },
        ]}
        showsVerticalScrollIndicator={false}
      >
        <Text style={styles.subtitle}>
          Essential safety tips to keep you secure while traveling
        </Text>

        {safetyCategories.map((category) => (
          <View key={category.id} style={styles.categoryCard}>
            <TouchableOpacity
              style={styles.categoryHeader}
              onPress={() => toggleCategory(category.id)}
              activeOpacity={0.7}
            >
              <View
                style={[
                  styles.iconContainer,
                  { backgroundColor: category.color },
                ]}
              >
                <category.icon size={24} color="#1A1A1A" />
              </View>
              <Text style={styles.categoryTitle}>{category.title}</Text>
            </TouchableOpacity>

            {expandedCategory === category.id && (
              <View style={styles.tipsContainer}>
                {category.tips.map((tip, index) => (
                  <View key={index} style={styles.tipItem}>
                    <View style={styles.tipBullet} />
                    <Text style={styles.tipText}>{tip}</Text>
                  </View>
                ))}
              </View>
            )}
          </View>
        ))}
      </ScrollView>
    </View>
  );
}
