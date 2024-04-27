package srp

import "testing"

func TestCalc_Add(t *testing.T) {
	type args struct {
		a int
		b int
	}
	tests := []struct {
		name string
		args args
		want int
	}{
		// TODO: Add test cases.
		{
			name: "addSuccess", args: args{a: 2, b: 2}, want: 4,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			c := &Calc{}
			if got := c.Add(tt.args.a, tt.args.b); got != tt.want {
				t.Errorf("Add() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestCalc_Sub(t *testing.T) {
	type args struct {
		a int
		b int
	}
	tests := []struct {
		name string
		args args
		want int
	}{
		// TODO: Add test cases.
		{
			name: "subSuccess", args: args{a: 2, b: 2}, want: 0,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			c := &Calc{}
			if got := c.Sub(tt.args.a, tt.args.b); got != tt.want {
				t.Errorf("Sub() = %v, want %v", got, tt.want)
			}
		})
	}
}
