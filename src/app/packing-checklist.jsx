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
import { ArrowLeft, CheckCircle, Circle } from "lucide-react-native";
import {
  useFonts,
  Nunito_400Regular,
  Nunito_500Medium,
  Nunito_600SemiBold,
} from "@expo-google-fonts/nunito";
import { Fredoka_500Medium } from "@expo-google-fonts/fredoka";
import { useTheme } from "@/utils/theme/useTheme";

const checklistCategories = [
  {
    id: "documents",
    title: "Documents & Money",
    items: [
      { id: "passport", label: "Passport" },
      { id: "visa", label: "Visa (if required)" },
      { id: "tickets", label: "Flight tickets" },
      { id: "hotel", label: "Hotel confirmations" },
      { id: "insurance", label: "Travel insurance" },
      { id: "cards", label: "Credit/debit cards" },
      { id: "cash", label: "Local currency" },
      { id: "license", label: "Driver's license" },
    ],
  },
  {
    id: "clothing",
    title: "Clothing",
    items: [
      { id: "underwear", label: "Underwear" },
      { id: "socks", label: "Socks" },
      { id: "shirts", label: "Shirts/tops" },
      { id: "pants", label: "Pants/shorts" },
      { id: "jacket", label: "Jacket/sweater" },
      { id: "shoes", label: "Comfortable shoes" },
      { id: "sandals", label: "Sandals/flip-flops" },
      { id: "swimwear", label: "Swimwear" },
    ],
  },
  {
    id: "toiletries",
    title: "Toiletries",
    items: [
      { id: "toothbrush", label: "Toothbrush & toothpaste" },
      { id: "shampoo", label: "Shampoo & conditioner" },
      { id: "soap", label: "Soap/body wash" },
      { id: "deodorant", label: "Deodorant" },
      { id: "sunscreen", label: "Sunscreen" },
      { id: "medications", label: "Medications" },
      { id: "firstaid", label: "First aid kit" },
      { id: "razor", label: "Razor" },
    ],
  },
  {
    id: "electronics",
    title: "Electronics",
    items: [
      { id: "phone", label: "Phone" },
      { id: "charger", label: "Phone charger" },
      { id: "adapter", label: "Power adapter" },
      { id: "camera", label: "Camera" },
      { id: "headphones", label: "Headphones" },
      { id: "laptop", label: "Laptop/tablet" },
      { id: "powerbank", label: "Power bank" },
    ],
  },
  {
    id: "misc",
    title: "Miscellaneous",
    items: [
      { id: "sunglasses", label: "Sunglasses" },
      { id: "hat", label: "Hat/cap" },
      { id: "umbrella", label: "Umbrella" },
      { id: "backpack", label: "Daypack/backpack" },
      { id: "water", label: "Water bottle" },
      { id: "snacks", label: "Snacks" },
      { id: "book", label: "Book/entertainment" },
      { id: "locks", label: "Luggage locks" },
    ],
  },
];

export default function PackingChecklistScreen() {
  const insets = useSafeAreaInsets();
  const { theme } = useTheme();
  const [checkedItems, setCheckedItems] = useState({});

  const [fontsLoaded] = useFonts({
    Nunito_400Regular,
    Nunito_500Medium,
    Nunito_600SemiBold,
    Fredoka_500Medium,
  });

  const toggleItem = (itemId) => {
    setCheckedItems((prev) => ({
      ...prev,
      [itemId]: !prev[itemId],
    }));
  };

  const getCategoryProgress = (category) => {
    const totalItems = category.items.length;
    const checkedCount = category.items.filter(
      (item) => checkedItems[item.id],
    ).length;
    return { total: totalItems, checked: checkedCount };
  };

  if (!fontsLoaded) return null;

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
      padding: 20,
      marginBottom: 16,
      borderWidth: 1,
      borderColor: theme.border,
    },
    categoryHeader: {
      flexDirection: "row",
      justifyContent: "space-between",
      alignItems: "center",
      marginBottom: 16,
    },
    categoryTitle: {
      fontFamily: "Nunito_600SemiBold",
      fontSize: 18,
      color: theme.text,
    },
    categoryProgress: {
      fontFamily: "Nunito_500Medium",
      fontSize: 14,
      color: theme.textSecondary,
    },
    checklistItem: {
      flexDirection: "row",
      alignItems: "center",
      paddingVertical: 10,
    },
    itemLabel: {
      flex: 1,
      fontFamily: "Nunito_400Regular",
      fontSize: 15,
      color: theme.text,
      marginLeft: 12,
    },
    itemLabelChecked: {
      textDecorationLine: "line-through",
      color: theme.textSecondary,
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
        <Text style={styles.headerTitle}>Packing Checklist</Text>
      </View>

      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={[
          styles.contentContainer,
          { paddingBottom: insets.bottom + 20 },
        ]}
        showsVerticalScrollIndicator={false}
      >
        <Text style={styles.subtitle}>Check off items as you pack them</Text>

        {checklistCategories.map((category) => {
          const progress = getCategoryProgress(category);
          return (
            <View key={category.id} style={styles.categoryCard}>
              <View style={styles.categoryHeader}>
                <Text style={styles.categoryTitle}>{category.title}</Text>
                <Text style={styles.categoryProgress}>
                  {progress.checked}/{progress.total}
                </Text>
              </View>

              {category.items.map((item) => (
                <TouchableOpacity
                  key={item.id}
                  style={styles.checklistItem}
                  onPress={() => toggleItem(item.id)}
                  activeOpacity={0.7}
                >
                  {checkedItems[item.id] ? (
                    <CheckCircle size={24} color="#34C759" fill="#34C759" />
                  ) : (
                    <Circle size={24} color={theme.textSecondary} />
                  )}
                  <Text
                    style={[
                      styles.itemLabel,
                      checkedItems[item.id] && styles.itemLabelChecked,
                    ]}
                  >
                    {item.label}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
          );
        })}
      </ScrollView>
    </View>
  );
}
